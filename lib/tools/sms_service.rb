class SmsService
  attr_reader :error

  def initialize(tel, type = :web_login)
    raise ArgumentError unless tel =~ /^1[0-9]{10}$/
    @tel = tel
    @type = type
  end

  # 验证码SMS
  def send_sms
    if TEST
      code = '123456' # for test
    else
      code = Tools.make_random_string
      res = Aliyun::Sms.send(@tel, VERIFICATION_CODE, { 'code' => code }.to_json, '').body
      res = JSON.parse(res)
      if res['Message'] != 'OK'
        @error = res['Message']
        return false
      end
    end
    Redis.new.set(key, code, ex: 600)
  end

  def verify_sms(code)
    Redis.new.get(key) == code ? Redis.new.del(key) : false
  end

  # 通知SMS
  # 管理员每日通知
  def send_manager_everyday_notice_sms(user, project_num, reservation_num)
    msg = {}.to_json
    code = ''
    Aliyun::Sms.send(@tel, EVERYDAY_NOTICE_CODE, msg.to_json, '') unless TEST
  end

  # 管理员收到待审核通知
  def review_notice_sms(reservation)
    project = ProjectRepository.new.find(reservation.project_id)
    customer = UserRepository.new.find(reservation.creator_id)
    manager = UserRepository.new.find(project.creator_id)
    msg = {
      manager_name: manager.name,
      customer_name: customer.name,
      tel: reservation.tel,
      address: project.name,
      date:    reservation.date,
      time:    reservation.time.first
    }.to_json
    res = Aliyun::Sms.send(@tel, REVIEW_NOTICE_CODE, msg, '') # unless TEST
    puts res.body
  end

  # 管理员取消预约，用户收到短信
  def manager_cancel_sms(reservation)
    project = ProjectRepository.new.find(reservation.project_id)
    customer = UserRepository.new.find(reservation.creator_id)
    msg = {
      customer_name: customer.name,
      address: project.name,
      date: reservation.date,
      time: reservation.time.first,
      reason: reservation.remark
    }.to_json
    res = Aliyun::Sms.send(@tel, MANAGER_CANCEL_CODE, msg, '') # unless TEST
    puts res.body
  end

  # 用户取消预约，用户收到短信
  def customer_cancel_sms(reservation) 
    project = ProjectRepository.new.find(reservation.project_id)
    customer = UserRepository.new.find(reservation.creator_id)
    msg = {
      customer_name: customer.name,
      address: project.name,
      date: reservation.date,
      time: reservation.time.first
    }.to_json
    code = 'SMS_135041424'
    res = Aliyun::Sms.send(@tel, CUSTOMER_CANCEL_CODE, msg, '') # unless TEST
    puts res.body
  end

  # 审核通过
  def success_notice_sms(reservation)
    project = ProjectRepository.new.find(reservation.project_id)
    customer = UserRepository.new.find(reservation.creator_id)
    msg = {
      customer_name: customer.name,
      address: project.name,
      date: reservation.date,
      time1: reservation.time.first
    }.to_json
    code = 'SMS_135026550'
    res = Aliyun::Sms.send(@tel, SUCCESS_NOTICE_CODE, msg, '')#  unless TEST
    puts res.body
  end

  # 提前1小时提醒短信
  def one_hour_notice_sms(reservation)
    project = ProjectRepository.new.find(reservation.project_id)
    customer = UserRepository.new.find(reservation.creator_id)
    msg = {
      customer_name: customer.name,
      address: project.name,
      date: reservation.date,
      time: reservation.time.first,
    }.to_json
    code = 'SMS_135036370'
    res = Aliyun::Sms.send(@tel, ONE_HOUR_NOTICE_CODE, msg, '') # unless TEST
    puts res.body
  end

  private

  # get key of redis
  def key
    "#{@tel}.#{@type}"
  end

  def standard_time(times)
    str = times.first
    str << '等' if a.length > 1
    str
  end
end
