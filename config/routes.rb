Rails.application.routes.draw do

  concern :range_searchable, BlacklightRangeLimit::Routes::RangeSearchable.new
  scope "(:locale)", locale: /en|fr|de|fi/ do
    devise_for :users
    post 'authenticate', to: 'api_authentication#authenticate'
    concern :exportable, Blacklight::Routes::Exportable.new

    resources :solr_documents, only: [:show], path: '/catalog', controller: 'catalog' do
      concerns :exportable
    end

    resources :bookmarks do
      concerns :exportable

      collection do
        delete 'clear'
      end
    end

      concern :searchable, Blacklight::Routes::Searchable.new

    resource :catalog, only: [:index], as: 'catalog', path: '/catalog', controller: 'catalog' do
      concerns :searchable
      concerns :range_searchable

    end

    concern :exportable, Blacklight::Routes::Exportable.new

    resources :solr_documents, only: [:show], path: '/catalog', controller: 'catalog' do
      concerns :exportable
    end

    resources :bookmarks do
      concerns :exportable

      collection do
        delete 'clear'
      end
    end

    mount Blacklight::Engine => '/'
    mount BlacklightAdvancedSearch::Engine => '/'
    # get 'advanced' => 'advanced#index'
    # get 'advanced/range_limit' => 'advanced#range_limit'


    get '/annotations/search', to: 'annotations#search'

    post '/annotations/add', to: 'annotations#add_annotation'

    get '/locales/:id/translation.json', to: 'assets#locale'

    get '/explore', to: 'catalog#explore'

    resources :feedbacks

    root to: "catalog#index"
    # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

    resources :datasets, :except => ['edit']

    post '/datasets/:id/delete_searches', to: 'datasets#delete_searches'
    post '/datasets/:id/rename', to: 'datasets#rename_dataset'
    post '/datasets/add', to: 'datasets#add'
    post '/datasets/create_and_add', to: 'datasets#create_and_add'
    post '/datasets/delete_elements', to: 'datasets#delete_elements'
    get '/datasets/rename_dataset_modal/:id', to: 'datasets#rename_dataset_modal'
    post '/datasets/apply_rename_dataset', to: 'datasets#apply_rename_dataset'

    get '/personal_research_assistant', to: 'personal_research_assistant#index'
    get '/personal_research_assistant/show_results/:task_uuid', to: 'personal_research_assistant#show_results'
    get '/personal_research_assistant/show_report/:task_uuid', to: 'personal_research_assistant#show_report'
    get '/personal_research_assistant/show_params/:task_uuid', to: 'personal_research_assistant#show_params'
    get '/personal_research_assistant/tm_show_results/:task_uuid', to: 'personal_research_assistant#tm_show_results'
    get '/personal_research_assistant/tm_show_params/:task_uuid', to: 'personal_research_assistant#tm_show_params'
    get '/personal_research_assistant/describe_topics/', to: 'personal_research_assistant#describe_topics'
    get '/personal_research_assistant/list_models', to: 'personal_research_assistant#list_models'
    post '/personal_research_assistant/tm_action', to: 'personal_research_assistant#tm_action'
    post '/personal_research_assistant/search', to: 'personal_research_assistant#search_task'
    post '/personal_research_assistant/create_search_task', to: 'personal_research_assistant#create_search_task'
    post '/personal_research_assistant/analyse', to: 'personal_research_assistant#analysis_task'
    post '/personal_research_assistant/investigate', to: 'personal_research_assistant#investigate_task'
    get '/update_tasks_status', to: 'personal_research_assistant#update_status'

    get '/personal_workspace/describe_search/:search_id', to: 'personal_workspace#describe_search'
    get '/personal_workspace/describe_dataset/:dataset_id', to: 'personal_workspace#describe_dataset'
    get '/personal_workspace/describe_search_modal/:run_uuid', to: 'personal_workspace#describe_search_modal'
    get '/personal_workspace/show/:task_id', to: 'personal_workspace#show'
    get '/personal_workspace/update_tasks', to: 'personal_workspace#update_tasks'
    get '/personal_workspace/get_run_report', to: 'personal_workspace#get_run_report'
    get '/personal_workspace/get_task_report', to: 'personal_workspace#get_task_report'
    post '/personal_workspace/get_task_results', to: 'personal_workspace#get_task_results'
    get '/personal_workspace/delete_task/:uuid', to: 'personal_workspace#delete_task'

    get '/personal_research_assistant/utilities', to: 'personal_research_assistant#get_utilities'
    post '/personal_research_assistant/user_tasks', to: 'personal_research_assistant#get_user_tasks'
    get '/personal_research_assistant/topic_models', to: 'personal_research_assistant#get_topic_models'
    post '/personal_research_assistant/render_utility', to: 'personal_research_assistant#render_utility'

    get '/search_help', to: 'catalog#help'
    get '/kw_suggest', to: 'catalog#kw_suggest'
    post '/tools/query_embd_model', to: 'catalog#query_embd_model'
    post '/catalog/set_working_dataset', to: 'catalog#set_working_dataset'
    post '/catalog/confirm_modify_dataset', to: 'catalog#confirm_modify_dataset'
    post '/catalog/apply_modify_dataset', to: 'catalog#apply_modify_dataset'
    post '/catalog/modify_doc_relevancy', to: 'catalog#modify_doc_relevancy'
    post '/catalog/article_parts', to: 'catalog#article_parts'
    post '/catalog/linked_entity_search', to: 'catalog#linked_entity_search'

    post "/saved_searches/save", to: "saved_searches#save"
    post "/saved_searches/confirm_save", to: "saved_searches#confirm_save"
    get "/saved_searches", to: "saved_searches#index"
    get '/delete_search/:id', to: 'saved_searches#delete_search'
    get "/personal_workspace", to: "personal_workspace#index"

    post "/list_datasets", to: "api_base#list_datasets"
    post "/get_dataset_content", to: "api_base#get_dataset_content"
    post "/export_dataset/zipped", to: "export#zipped_export"
    post "/export_dataset/csv", to: "export#csv_export"
    post "/export_dataset/json", to: "export#json_export"
    post "/datasets/merge", to: "datasets#merge_dataset_modal"
    post "/datasets/apply_merge_dataset", to: "datasets#apply_merge_dataset"
    post "/datasets/subdataset", to: "datasets#subdataset_modal"
    post "/datasets/apply_subdataset", to: "datasets#apply_subdataset"

  end

  mount Riiif::Engine => '/iiif', as: 'riiif'

  get '/get_stats', to: 'catalog#get_stats'
  get '/iiif/:id/manifest.json', to: 'iiif#manifest'
  get '/iiif/:id/annotated_manifest.json', to: 'iiif#manifest_with_annotations'
  get '/iiif/:id/list/:name', to: 'iiif#annotation_list'
  get '/iiif/:id/layer/:name', to: 'iiif#layer'
  get '/iiif/:id/alto', to: 'iiif#alto'

  get '/test', to: 'personal_research_assistant#visualize_tm'

end
