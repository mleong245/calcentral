require 'selenium-webdriver'

class WebDriverUtils

  def self.driver
    if Settings.ui_selenium.webDriver == 'firefox'
      Rails.logger.info('Browser is Firefox')
      Selenium::WebDriver.for :firefox
    elsif Settings.ui_selenium.webDriver['webDriver'] == 'chrome'
      Rails.logger.info('Browser is Chrome')
      Selenium::WebDriver.for :chrome
    elsif Settings.ui_selenium.webDriver['webDriver'] == 'safari'
      Rails.logger.info('Browser is Safari')
      Selenium::WebDriver.for :safari
    end
  rescue
    puts 'No driver defined'
  end

  def self.base_url
    Settings.ui_selenium.baseUrl
  end

  def self.cal_net_url
    Settings.ui_selenium.calNetUrl
  end

  def self.page_load_timeout
    Settings.ui_selenium.pageLoadTimeout
  end

  def self.financials_timeout
    Settings.ui_selenium.financialsTimeout
  end

  def self.fin_resources_links_timeout
    Settings.ui_selenium.finResourcesLinksTimeout
  end

  def self.page_event_timeout
    Settings.ui_selenium.pageEventTimeout
  end

  def self.live_users
    Rails.root.join('fixtures', 'ui_selenium', 'uids.csv')
  end

end