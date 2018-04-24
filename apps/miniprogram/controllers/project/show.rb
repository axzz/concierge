module Miniprogram::Controllers::Project
  # Api for get one project
  class Show
    include Miniprogram::Action
    DISPLAY_NUM = 7
    DISPLAY_NUM.freeze

    def call(params)
      project = ProjectRepository.new.find(params[:id].to_i)
      halt 404 unless project
      time_table = DayTableRepository.new(project.id).get_tables(DISPLAY_NUM)
      time_state_parsed = sort_time_state(project.time_state_parsed)

      self.body = {
        cover:        project.image_url,
        name:         project.name,
        description:  project.description || '',
        address:      project.address     || '',
        latitude:     project.latitude    || '',
        longitude:    project.longitude   || '',
        time_state:   time_state_parsed,
        time_table:   time_table.to_json,
        tmp_tel:      @user.tmp_tel       || '',
        tmp_name:     @user.tmp_name      || ''
      }.to_json
    end

    private
    
    # Solve postgres incorrect sort
    def sort_time_state(time_state)
      { Mon:     time_state[:Mon],
        Tues:    time_state[:Tues],
        Wed:     time_state[:Wed],
        Thur:    time_state[:Thur],
        Fri:     time_state[:Fri],
        Sat:     time_state[:Sat],
        Sun:     time_state[:Sun],
        Holiday: time_state[:Holiday],
        Special: time_state[:Special] }
    end
  end
end