class Task < ApplicationRecord
  belongs_to :user
  belongs_to :dataset, required: false
  belongs_to :search, required: false
  has_one :experiment, required: false
  # after_create :generate_subtasks

  def subtasks
    case self.task_type
    when 'investigator'
      out_sub_tasks = []
      unless self.results.nil?
        subs_uuids = self.results['result']
        subs_uuids.keys.each do |sub_uuid|
          subtask = Task.where(uuid: sub_uuid).first
          if subtask
            out_sub_tasks << subtask
          else
            Rails.logger.debug("Subtask not found, creating it...")
            data = PersonalResearchAssistantService.get_analysis_task sub_uuid
            Task.create(user: self.user, status: data['task_status'], uuid: data['uuid'],
                        started: data['task_started'], finished: data['task_finished'],
                        task_type: data['task_type'], parameters: data['task_parameters'],
                        results: data['task_result'], subtask: true)
          end
        end
      end
      out_sub_tasks
    when 'describe_search', 'describe_dataset'
      out_sub_tasks = []
      unless self.results.nil?
        # self.results['result'].each do |res|
        self.results.each do |res|
          subtask = Task.where(uuid: res['uuid']).first
          if subtask
            out_sub_tasks << subtask
          else
            Rails.logger.debug("Subtask not found, creating it...")
            data = PersonalResearchAssistantService.get_analysis_task res['uuid']
            puts data
            t = Task.create(user: self.user, status: data['task_status'], uuid: data['uuid'],
                            started: data['task_started'], finished: data['task_finished'],
                            task_type: data['task_type'], parameters: data['parameters'],
                            results: data['task_result'], subtask: true)
            out_sub_tasks << t
          end
        end
      end
      out_sub_tasks
    else
      []
    end
  end

  # private
  #
  # def generate_subtasks
  #   unless self.results.nil?
  #     if self.task_type == 'investigator'
  #       subs_uuids = self.results['result']
  #       subs_uuids.keys.each do |sub_uuid|
  #         data = PersonalResearchAssistantService.get_analysis_task sub_uuid
  #         Task.create(user: self.user, status: data['task_status'], uuid: data['uuid'],
  #                     started: data['task_started'], finished: data['task_finished'],
  #                     task_type: data['task_type'], parameters: data['task_parameters'],
  #                     results: data['task_result'], subtask: true)
  #       end
  #     end
  #   end
  # end

end