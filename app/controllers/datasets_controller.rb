class DatasetsController < ApplicationController

  before_action :set_dataset, only: [:show, :edit, :update, :destroy, :delete_elements, :rename_dataset_modal]
  before_action :authorize_pra, only: [:list_datasets, :get_dataset_content]

  # GET /datasets
  # GET /datasets.json
  def index
    @datasets = Dataset.all
  end

  # GET /datasets/1
  # GET /datasets/1.json
  def show
    @documents_list = @dataset.fetch_documents
    @documents_list.sort_by! do |doc|
      case params[:sort]
      when "date"
        Date.parse(doc['date_created_dtsi'])
      when "relevancy"
        doc['relevancy']
      end
    end
    @documents_list.reverse! if params[:sort_order] == "desc"
  end

  # GET /datasets/new
  def new
    @dataset = Dataset.new
  end

  # POST /datasets
  # POST /datasets.json
  def create
    dataset_params_copy = dataset_params
    @dataset = Dataset.create(dataset_params_copy)
    respond_to do |format|
      if @dataset.save
        format.html { redirect_to @dataset, notice: 'Dataset was successfully created.' }
        format.json { render :show, status: :created, location: @dataset }
      else
        puts @dataset.errors.inspect
        format.html { render :new }
        format.json { render json: @dataset.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /datasets/1
  # PATCH/PUT /datasets/1.json
  def update
    respond_to do |format|
      if @dataset.update(dataset_params)
        format.html { redirect_to request.referer, alert: 'Dataset was successfully updated.' }
        format.js { render partial: "datasets/confirm_add", locals: {message: 'Dataset was successfully updated.', status: 'success'}}
        format.json { render :show, status: :ok, location: @dataset }
      else
        format.html { render :edit }
        format.js { render partial: "datasets/confirm_add", locals: {message: 'Error updating dataset', status: 'warning'}}
        format.json { render json: @dataset.errors, status: :unprocessable_entity }
      end
    end
  end

  # POST /datasets/1/delete_searches
  def delete_searches
    to_delete = dataset_params[:searches_to_remove]
    @dataset.searches -= to_delete
    @dataset.save
    respond_to do |format|
      format.html {redirect_to request.referer, alert: 'Dataset was successfully updated.'}
      format.json {redirect_to request.referer, alert: 'Dataset was successfully updated.'}
    end
  end

  def delete_elements
    @dataset.searches -= params[:searches][0].split(',')
    @dataset.issues -= params[:issues][0].split(',')
    @dataset.articles -= params[:articles][0].split(',')
    @dataset.save
    begin
      @dataset.save!
      message = "Items were removed successfully."
      status = "success"
    rescue
      message = "Error removing items"
      status = "warning"
    end
    respond_to do |format|
      format.js { render partial: "datasets/confirm_delete", locals: {message: message, status: status}}
    end
  end

  # POST /datasets/add
  def add
    @dataset = Dataset.find(dataset_params[:id])
    if dataset_params[:issue]
      @dataset.issues << dataset_params[:issue] unless @dataset.issues.include? dataset_params[:issue]
    end
    if dataset_params[:search]
      @dataset.searches << dataset_params[:search] unless @dataset.searches.include? dataset_params[:search]
    end
    if dataset_params[:article]
      @dataset.articles << dataset_params[:article] unless @dataset.articles.include? dataset_params[:article]
    end
    begin
      @dataset.save!
      message = "Item was added successfully."
      status = "success"
    rescue
      message = "Error adding item"
      status = "warning"
    end
    respond_to do |format|
      format.js { render partial: "datasets/confirm_add", locals: {message: message, status: status}}
    end
  end

  # POST /datasets/create_and_add
  def create_and_add
    @dataset = Dataset.new
    @dataset.user_id = current_user.id
    @dataset.title = dataset_params[:title]
    if dataset_params[:issue]
      @dataset.issues << dataset_params[:issue]
    end
    if dataset_params[:search]
      @dataset.searches << dataset_params[:search]
    end
    if dataset_params[:article]
      @dataset.articles << dataset_params[:article]
    end
    begin
      @dataset.save!
      message = "Dataset was successfully created."
      status = "success"
    rescue ActiveRecord::RecordInvalid => e
      message = "A dataset with this name already exists."
      status = "warning"
    end
    respond_to do |format|
      format.js { render partial: "datasets/confirm_add", locals: {message: message, status: status}}
    end
  end

  # DELETE /datasets/1
  # DELETE /datasets/1.json
  def destroy
    @dataset.destroy
    respond_to do |format|
      format.html { redirect_to '/workspace', notice: 'Dataset was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def rename_dataset_modal
    respond_to do |format|
      format.js
    end
  end

  def apply_rename_dataset
    d = Dataset.find(params[:dataset_id])
    d.title = params[:new_title]
    d.save!
    respond_to do |format|
      format.html { redirect_to dataset_path(d), turbolinks: true, notice: 'Dataset title was successfully updated.' }
    end
  end

  def merge_dataset_modal
    respond_to do |format|
      format.js
    end
  end

  def apply_merge_dataset
    d = Dataset.find(params[:dataset_id])
    to_merge = Dataset.find(params[:dataset_id_to_merge])

    respond_to do |format|
      format.html { redirect_to dataset_path(d), turbolinks: true, notice: 'Dataset title was successfully updated.' }
    end
  end

  def list_datasets
    datasets = User.find_by_email(params[:email]).datasets
    render json: datasets.map(&:title)
  end

  def get_dataset_content
    datasets = User.find_by_email(params[:email]).datasets
    dataset_docs = datasets.to_a.select{|dt| dt.title == "pih"}[0].documents
    render json: dataset_docs
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_dataset
      @dataset = Dataset.find(params[:id])
    end

    def authorize_pra
      render json: "not authorized" unless current_user.email == "pra@newseye.eu"
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def dataset_params
      params.require(:dataset).permit(:id, :title, :user_id, :search, :issue, :article, searches_to_remove: [])
    end
end
