class GradeTestJob < ApplicationJob
  queue_as :default

  def perform test_result_id
    test_result = TestResult.find_by(id: test_result_id)

    return if test_result.nil? || test_result.submitted?

    TestGradingService.call(test_result)
  end
end
