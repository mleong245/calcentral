require 'spec_helper'
require 'selenium-webdriver'
require 'page-object'
require 'csv'
require 'json'
require_relative 'util/web_driver_utils'
require_relative 'util/user_utils'
require_relative 'pages/cal_central_pages'
require_relative 'pages/splash_page'
require_relative 'pages/my_academics_semesters_card'
require_relative 'pages/my_academics_enrollments_card'
require_relative 'pages/my_academics_class_page'
require_relative 'pages/api_my_status_page'
require_relative 'pages/api_my_classes_page'
require_relative 'pages/api_my_academics_page_semesters'

describe 'My Academics enrollments', :testui => true do

  if ENV["UI_TEST"]

    include ClassLogger

    begin

      driver = WebDriverUtils.driver

      test_users = UserUtils.load_test_users
      test_output = UserUtils.initialize_output_csv(self)
      testable_users = []

      CSV.open(test_output, 'wb') do |user_info_csv|
        user_info_csv << ['UID', 'Semester', 'CCN', 'Course Code', 'Course Title', 'Section', 'Grade Option', 'Units', 'Wait List Position']
      end

      test_users.each do |user|
        if user['enrollments']
          uid = user['uid'].to_s
          logger.info("UID is #{uid}")

          begin
            splash_page = CalCentralPages::SplashPage.new(driver)
            splash_page.load_page(driver)
            splash_page.basic_auth(driver, uid)
            status_api_page = ApiMyStatusPage.new(driver)
            status_api_page.get_json(driver)
            if status_api_page.has_student_history? && status_api_page.has_academics_tab?
              testable_users.push(uid)
              academics_api_page = ApiMyAcademicsPageSemesters.new(driver)
              academics_api_page.get_json(driver)
              all_semesters = academics_api_page.all_semesters
              all_semester_names = academics_api_page.semester_names(all_semesters)
              default_semester_names = academics_api_page.semester_names academics_api_page.default_semesters_in_ui

              my_academics = CalCentralPages::MyAcademicsSemestersCard.new(driver)
              my_academics.load_page(driver)
              my_academics.page_heading_element.when_visible(timeout=WebDriverUtils.academics_timeout)

              # MY ACADEMICS PAGE SEMESTER CARDS

              shows_default_semesters = my_academics.student_terms_visible?(default_semester_names)
              if all_semesters.any?
                it "shows future, current, and most recent past semester by default for UID #{uid}" do
                  expect(shows_default_semesters).to be true
                end
                show_more_button_visible = my_academics.show_more_element.visible?
                if all_semester_names.length > default_semester_names.length
                  it "offers a 'Show More' button for UID #{uid}" do
                    expect(show_more_button_visible).to be true
                  end
                  my_academics.show_more
                  shows_more_semesters = my_academics.student_terms_visible?(all_semester_names)
                  it "can show all semesters for UID #{uid}" do
                    expect(shows_more_semesters).to be true
                  end
                else
                  it "offers no 'Show More' button for UID #{uid}" do
                    expect(show_more_button_visible).to be false
                  end
                end

                all_semesters.each do |semester|
                  if my_academics.show_more_element.visible?
                    my_academics.show_more
                  end
                  begin
                    semester_name = academics_api_page.semester_name(semester)
                    semester_courses = academics_api_page.semester_courses(semester)
                    semester_card_courses = academics_api_page.courses_per_transcript(semester_courses)

                    api_course_codes = academics_api_page.course_codes(semester_card_courses)
                    api_course_titles = academics_api_page.course_titles(semester_card_courses)
                    api_units = academics_api_page.units_per_transcript(semester_courses)
                    api_grades = academics_api_page.grades(semester_courses, semester)

                    academics_page_course_codes = my_academics.prim_sec_course_codes(driver, semester_name)
                    academics_page_course_titles = my_academics.course_titles(driver, semester_name)
                    academics_page_course_units = my_academics.units(driver, semester_name)
                    academics_page_course_grades = my_academics.grades(driver, semester_name)

                    it "shows the course codes for #{semester_name} for UID #{uid}" do
                      expect(academics_page_course_codes).to eql(api_course_codes)
                      expect(academics_page_course_codes.all? &:blank?).to be false
                    end
                    it "shows the course titles for #{semester_name} for UID #{uid}" do
                      expect(academics_page_course_titles).to eql(api_course_titles)
                      expect(academics_page_course_titles.all? &:blank?).to be false
                    end
                    it "shows the course units for #{semester_name} for UID #{uid}" do
                      expect(academics_page_course_units).to eql(api_units)
                      expect(academics_page_course_units.all? &:blank?).to be false
                    end
                    it "shows the grades for #{semester_name} for UID #{uid}" do
                      expect(academics_page_course_grades).to eql(api_grades)
                    end

                    # SEMESTER PAGES

                    my_academics.click_semester_link(driver, semester_name)
                    semester_page = CalCentralPages::MyAcademicsPage::MyAcademicsEnrollmentsCard.new(driver)
                    wait_list_courses = academics_api_page.wait_list_courses(semester_courses)
                    enrolled_courses = (semester_courses - wait_list_courses)
                    semester_page_enrolled_courses = academics_api_page.courses_per_prim_section(enrolled_courses)

                    # ENROLLED COURSES

                    api_enrolled_course_codes = academics_api_page.course_codes(semester_page_enrolled_courses)
                    api_enrolled_course_titles = academics_api_page.course_titles(semester_page_enrolled_courses)
                    api_enrolled_grade_options = academics_api_page.course_grade_options(enrolled_courses)
                    api_enrolled_units = academics_api_page.units_per_prim_section(enrolled_courses)
                    api_enrolled_section_labels = academics_api_page.all_section_labels(enrolled_courses)

                    semester_page_codes = semester_page.all_enrolled_course_codes
                    semester_page_titles = semester_page.all_enrolled_course_titles
                    semester_page_grade_options = semester_page.all_enrolled_grade_options
                    semester_page_units = semester_page.all_enrolled_units
                    semester_page_sections = semester_page.all_enrolled_sections

                    it "shows the enrolled course codes on the #{semester_name} semester page for UID #{uid}" do
                      expect(semester_page_codes).to eql(api_enrolled_course_codes)
                      expect(semester_page_codes.all? &:blank?).to be false
                    end
                    it "shows the enrolled course titles on the #{semester_name} semester page for UID #{uid}" do
                      expect(semester_page_titles).to eql(api_enrolled_course_titles)
                      expect(semester_page_titles.all? &:blank?).to be false
                    end
                    it "shows the enrolled course grade options on the #{semester_name} semester page for UID #{uid}" do
                      expect(semester_page_grade_options).to eql(api_enrolled_grade_options)
                      expect(semester_page_grade_options.all? &:blank?).to be false
                    end
                    it "shows the enrolled course units on the #{semester_name} semester page for UID #{uid}" do
                      expect(semester_page_units).to eql(api_enrolled_units)
                      expect(semester_page_units.all? &:blank?).to be false
                    end
                    it "shows the enrolled section labels on the #{semester_name} semester page for UID #{uid}" do
                      expect(semester_page_sections).to eql(api_enrolled_section_labels)
                      expect(semester_page_sections.all? &:blank?).to be false
                    end

                    # WAIT LIST COURSES

                    if wait_list_courses.any?
                      api_wait_list_course_codes = academics_api_page.wait_list_course_codes(wait_list_courses)
                      api_wait_list_course_titles = academics_api_page.wait_list_course_titles(wait_list_courses)
                      api_wait_list_sections = academics_api_page.all_section_labels(wait_list_courses)
                      api_wait_list_positions = academics_api_page.wait_list_positions(wait_list_courses)
                      api_wait_list_sizes = academics_api_page.enrollment_limits(wait_list_courses)

                      sem_page_wait_list_codes = semester_page.all_waitlist_course_codes
                      sem_page_wait_list_titles = semester_page.all_waitlist_course_titles
                      sem_page_wait_list_sections = semester_page.all_waitlist_sections
                      sem_page_wait_list_positions = semester_page.all_waitlist_positions
                      sem_page_wait_list_sizes = semester_page.all_waitlist_class_sizes

                      it "shows the wait list course codes on the #{semester_name} semester page for UID #{uid}" do
                        expect(sem_page_wait_list_codes).to eql(api_wait_list_course_codes)
                        expect(sem_page_wait_list_codes.all? &:blank?).to be false
                      end
                      it "shows the wait list course titles on the #{semester_name} semester page for UID #{uid}" do
                        expect(sem_page_wait_list_titles).to eql(api_wait_list_course_titles)
                        expect(sem_page_wait_list_titles.all? &:blank?).to be false
                      end
                      it "shows the wait list sections on the #{semester_name} semester page for UID #{uid}" do
                        expect(sem_page_wait_list_sections).to eql(api_wait_list_sections)
                        expect(sem_page_wait_list_sections.all? &:blank?).to be false
                      end
                      it "shows the wait list positions on the #{semester_name} semester page for UID #{uid}" do
                        expect(sem_page_wait_list_positions).to eql(api_wait_list_positions)
                        expect(sem_page_wait_list_positions.all? &:blank?).to be false
                      end
                      it "shows the wait list sizes on the #{semester_name} semester page for UID #{uid}" do
                        expect(sem_page_wait_list_sizes).to eql(api_wait_list_sizes)
                        expect(sem_page_wait_list_sizes.all? &:blank?).to be false
                      end
                    end

                    # CLASS PAGES

                    semester_courses.each do |course|
                      begin
                        api_course_code = academics_api_page.course_code(course)
                        api_course_title = academics_api_page.course_title(course)
                        api_course_instructors = academics_api_page.course_instructor_names(course)
                        api_sections = academics_api_page.sections(course)
                        api_section_labels = academics_api_page.section_labels(course)
                        api_section_ccns = academics_api_page.section_ccns(course)
                        api_section_units = academics_api_page.section_units(course)
                        api_grade_options = academics_api_page.section_grade_options(course)
                        api_section_schedules = academics_api_page.course_section_schedules(course)

                        semester_page.click_class_link(driver, api_course_code)
                        class_page = CalCentralPages::MyAcademicsClassPage.new(driver)
                        class_page.class_info_heading_element.when_visible(WebDriverUtils.page_load_timeout)

                        class_page_breadcrumb = class_page.class_breadcrumb
                        class_page_course_title = class_page.course_title
                        class_page_course_role = class_page.role
                        class_page_section_labels = class_page.all_section_schedule_labels
                        class_page_section_ccns = class_page.all_student_section_ccns
                        class_page_section_units = class_page.all_section_units
                        class_page_grade_options = class_page.all_section_grade_options
                        class_page_section_schedules = class_page.all_section_schedules
                        class_page_course_instructors = class_page.all_course_instructors(driver, api_section_labels)

                        it "shows #{api_course_code} in the class page breadcrumb for #{semester_name} for UID #{uid}" do
                          expect(class_page_breadcrumb).to eql(api_course_code)
                        end
                        it "shows the class title on the #{semester_name} #{api_course_code} class page for UID #{uid}" do
                          expect(class_page_course_title).to eql(api_course_title)
                          expect(class_page_course_title.blank?).to be false
                        end
                        it "shows the student role on the #{semester_name} #{api_course_code} class page for UID #{uid}" do
                          expect(class_page_course_role).to eql('Student')
                        end
                        it "shows the enrolled section labels on the #{semester_name} #{api_course_code} class page for UID #{uid}" do
                          expect(class_page_section_labels).to eql(api_section_labels)
                          expect(class_page_section_labels.all? &:blank?).to be false
                        end
                        it "shows the enrolled section CCNs on the #{semester_name} #{api_course_code} class page for UID #{uid}" do
                          expect(class_page_section_ccns).to eql(api_section_ccns)
                          expect(class_page_section_ccns.all? &:blank?).to be false
                        end
                        it "shows the section units on the #{semester_name} #{api_course_code} class page for UID #{uid}" do
                          expect(class_page_section_units).to eql(api_section_units)
                          expect(class_page_section_units.all? &:blank?).to be false
                        end
                        it "shows the section grade options on the #{semester_name} #{api_course_code} class page for UID #{uid}" do
                          expect(class_page_grade_options).to eql(api_grade_options)
                          expect(class_page_grade_options.all? &:blank?).to be false
                        end
                        it "shows the section schedules on the #{semester_name} #{api_course_code} class page for UID #{uid}" do
                          expect(class_page_section_schedules).to eql(api_section_schedules)
                        end
                        it "shows the section instructors on the #{semester_name} #{api_course_code} class page for UID #{uid}" do
                          expect(class_page_course_instructors).to eql(api_course_instructors)
                        end

                        if academics_api_page.current_semester.include?(semester) || academics_api_page.future_semesters.include?(semester)
                          api_sections.each do |section|
                            i = api_sections.index(section)
                            CSV.open(test_output, 'a+') do |user_info_csv|
                              user_info_csv << [uid, semester_name, api_section_ccns[i], api_course_code, api_course_title, api_section_labels[i],
                                                api_grade_options[i], api_section_units[i], academics_api_page.wait_list_position(section)]
                            end
                          end
                        end

                        class_page.back
                      end
                    end

                    semester_page.back
                  end
                end
              else
                it "shows no semesters for UID #{uid}" do
                  expect(shows_default_semesters).to be false
                end
              end
            end

          rescue => e
            logger.error e.message + "\n" + e.backtrace.join("\n ")
          end
        end

        it 'has enrollment information for at least one of the test UIDs' do
          expect(testable_users.length).to be > 0
        end
      end

    rescue => e
      logger.error e.message + "\n" + e.backtrace.join("\n ")
    ensure
      logger.info('Quitting the browser')
      driver.quit
    end
  end
end