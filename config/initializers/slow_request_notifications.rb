if Settings.logger.slow_request_threshold_in_ms.default.to_i > 0
  Rails.logger.warn "Logging all requests slower than #{Settings.logger.slow_request_threshold_in_ms.default.to_i}ms"
  ActiveSupport::Notifications.subscribe "process_action.action_controller" do |name, start, finish, id, payload|
    duration = (finish - start) * 1000
    view_time = 0
    db_time = 0
    unless payload[:view_runtime].nil?
      view_time = payload[:view_runtime]
    end
    unless payload[:db_runtime].nil?
      db_time = payload[:db_runtime]
    end
    threshold = Settings.logger.slow_request_threshold_in_ms.send(payload[:path]) || Settings.logger.slow_request_threshold_in_ms.default
    if duration > threshold.to_i
      Rails.logger.error "SLOW REQUEST #{payload[:path]}; view=#{view_time.to_i}ms db=#{db_time.to_i}ms total=#{duration.to_i}ms"
    end
  end
end
