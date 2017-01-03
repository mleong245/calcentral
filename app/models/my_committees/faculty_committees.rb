module MyCommittees
  class FacultyCommittees

    include CommitteesModule
    include ClassLogger

    def merge(feed)
      feed.merge! get_feed
    end

    def get_feed
      result = {
        facultyCommittees: {
          active: [],
          completed: []
        }
      }
      feed = CampusSolutions::FacultyCommittees.new(user_id: @uid).get[:feed]
      if feed && (cs_committees = feed[:ucSrFacultyCommittee].try(:[], :facultyCommittees))
        # Service range will be parsed from nested member data with match on emplid
        @emplid = feed[:ucSrFacultyCommittee].try(:[], :emplid)
        result[:facultyCommittees] = parse_cs_faculty_committees(cs_committees , result[:facultyCommittees])
      end
      result
    end

    def parse_cs_faculty_committees (cs_committees, committees_result)
      cs_committees.compact!
      cs_committees.try(:each) do |cs_committee|
        is_completed = cs_committee[:studentMilestoneCompleteDate].present?
        faculty_committee = parse_cs_committee(cs_committee, is_completed)
        if cs_committee.present?
          # Add additional pieces of data needed faculty committees
          cs_faculty_committee_svc = parse_cs_faculty_committee_svc(cs_committee)
          faculty_committee.merge!(
            student: parse_cs_committee_student(cs_committee),
            serviceRange: cs_faculty_committee_svc[:serviceRange],
            csMemberEndDate: cs_faculty_committee_svc[:memberEndDate],
            csMemberStartDate: cs_faculty_committee_svc[:memberStartDate]
          )
          if is_completed
            committees_result[:completed] << faculty_committee
          else
            committees_result[:active] << faculty_committee
          end
        end
      end
      committees_result[:completed] = sort_committees_by_svc(committees_result[:completed])
      committees_result[:active] = sort_committees_by_svc(committees_result[:active])
      committees_result
    end

    def sort_committees_by_svc(cs_committees)
      cs_committees.try(:sort_by) do |committee|
        # set the enddate to 9999-99-99 to allow for sort_by to do string comparison.
        # sort_by does not allow for us to change the sorting logic based on nil values in the block.
        # we can only pass back a default value to be used in sorting algorithm beyond the code block.
        # sort_by is more efficient than sort when performing operations on sorted variable.
        [committee[:csMemberEndDate] || '9999-99-99', committee[:csMemberStartDate] || '']
      end.try(:reverse)
    end

    def parse_cs_faculty_committee_svc (cs_committee)
      committee_service_range_result = ''
      user_committee = cs_committee[:committeeMembers].try(:find) do |mem|
        mem[:memberEmplid].present? &&  mem[:memberEmplid] == @emplid
      end
      start_date = user_committee.try(:[], :memberStartDate)
      end_date = user_committee.try(:[], :memberEndDate)
      committee_service_range_result = {
        serviceRange: "#{ format_date(start_date) } - #{ format_date(end_date) }",
        memberEndDate: end_date,
        memberStartDate: start_date
      } if user_committee
      committee_service_range_result
    end

  end
end
