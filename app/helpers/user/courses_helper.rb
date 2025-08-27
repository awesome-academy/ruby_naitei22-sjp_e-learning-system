module User::CoursesHelper
  def enrolment_status_options
    [
      [t(".status_all"), nil],
      [t(".pending"), :pending],
      [t(".rejected"), :rejected],
      [t(".approved"), :approved],
      [t(".in_progress"), :in_progress],
      [t(".completed"), :completed],
      [t(".not_enrolled"), :not_enrolled]
    ]
  end

  def enrollee_bucket_options
    [
      [t(".enrollees.1_to_10"),  "1-10"],
      [t(".enrollees.11_to_20"), "11-20"],
      [t(".enrollees.21_to_30"), "21-30"],
      [t(".enrollees.31_plus"), "31+"]
    ]
  end
end
