# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# --- WARNING: This script will destroy all existing data in the tables. ---
# --- CẢNH BÁO: Script này sẽ xóa tất cả dữ liệu hiện có trong các bảng. ---

require "faker"
require "securerandom"

puts "Starting database seeding..."
puts "----------------------------"

# BƯỚC 1: Xóa dữ liệu cũ để tránh trùng lặp
puts "Clearing existing data..."
UserWord.destroy_all
TestResult.destroy_all
Answer.destroy_all
Question.destroy_all
UserLesson.destroy_all
UserCourse.destroy_all
Component.destroy_all
Lesson.destroy_all
AdminCourseManager.destroy_all
Test.destroy_all
Course.destroy_all
Word.destroy_all
User.destroy_all
puts "Existing data cleared successfully."
puts "----------------------------"

# Helper method để tạo bản ghi và in lỗi (nếu có)
def create_record(model, attributes)
  record = model.create(attributes)
  unless record.persisted?
    puts "Failed to create #{model.name} with attributes: #{attributes}"
    puts "Errors: #{record.errors.full_messages.to_sentence}"
    return nil
  end
  record
end

# BƯỚC 2: Tạo người dùng, bao gồm một admin và 50 người dùng thường
puts "Creating users..."

# Tạo admin
admin_user = User.create!(
  name: "Admin",
  email: "admin@gmail.com",
  password: "123456",
  password_confirmation: "123456",
  birthday: Date.new(1990, 1, 1),
  gender: "other",
  role: "admin",
  provider: nil,
  uid: nil
)
puts "- Created admin user: #{admin_user.name}"

# Tạo user thường
users = [admin_user]
20.times do
  name = Faker::Name.name
  email = Faker::Internet.unique.email
  birthday = Faker::Date.birthday(min_age: 18, max_age: 30)
  gender = %w[male female other].sample

  user = create_record(User, {
    name: name,
    email: email,
    password: "123456",
    password_confirmation: "123456",
    birthday: birthday,
    gender: gender,
    role: "user",
    provider: nil,
    uid: nil
  })
  users << user if user
end
puts "- Created #{users.count - 1} normal users."
puts "----------------------------"

# BƯỚC 3: Thêm từ vựng từ file JSON
puts "Creating words from JSON..."
words = []
json_file_path = Rails.root.join("english_words.json")

if File.exist?(json_file_path)
  puts "JSON file found at: #{json_file_path}"
  begin
    # Đọc nội dung tệp JSON và phân tích cú pháp
    json_data = File.read(json_file_path)
    data = JSON.parse(json_data)

    data.each do |word_data|
      english = word_data["english"]
      type_abbr = word_data["type"]
      vietnamese = word_data["vietnamese"]

      # Ánh xạ các từ viết tắt trong JSON sang các giá trị enum đầy đủ
      type_map = {
        "n." => :noun, "v." => :verb, "adj." => :adjective, "adv." => :adverb,
        "prep." => :preposition, "conj." => :conjunction, "pron." => :pronoun,
        "int." => :interjection,
      }
      mapped_type = type_map[type_abbr&.split(",")&.first&.strip] || :noun

      word = create_record(Word, {
        content: english,
        meaning: vietnamese,
        word_type: mapped_type
      })

      words << word if word
    end
    puts "- Created #{words.count} words from JSON."
  rescue JSON::ParserError => e
    puts "JSON Error: Failed to parse JSON file. Please check for syntax errors. Error message: #{e.message}"
  rescue StandardError => e
    puts "An unexpected error occurred while processing the JSON file: #{e.message}"
  end
else
  puts "Error: \"english_words.json\" not found at #{json_file_path}. Seeding aborted."
  return
end
puts "----------------------------"

# Kiểm tra xem có đủ dữ liệu để seed không
if words.empty? || users.empty?
  puts "Not enough data (words or users) to proceed. Seeding aborted."
  return
end

# BƯỚC 4: Tạo các khóa học và bài học
puts "Creating courses and lessons..."
courses = []
lessons = []
20.times do
  course = create_record(Course, {
    title: Faker::Educator.course_name,
    description: Faker::Lorem.paragraph(sentence_count: 5),
    created_by_id: admin_user.id,
    duration: Faker::Number.between(from: 45, to: 60)
  })
  if course
    courses << course
    puts "-- Created course: #{course.title}"

    create_record(AdminCourseManager, { user: admin_user, course: course })

    10.times do |i|
      lesson = create_record(Lesson, {
        course: course,
        title: "Lesson #{i + 1}: #{Faker::Book.title}",
        description: Faker::Lorem.paragraph(sentence_count: 3),
        position: i + 1,
        created_by_id: admin_user.id
      })
      lessons << lesson if lesson
      puts "---- Created lesson: #{lesson.title}" if lesson
    end
  end
end
puts "----------------------------"

# BƯỚC 5: Tạo components, bài kiểm tra, câu hỏi và đáp án
puts "Creating components, tests, questions, and answers..."
lesson_words = {}
lesson_tests = {}
lessons.each do |lesson|
  words_for_lesson = words.sample(10)
  words_for_lesson.each_with_index do |word, i|
    create_record(Component, {
      lesson: lesson,
      component_type: :word,
      word: word,
      index_in_lesson: i
    })
  end

  test = create_record(Test, {
    name: "Test for Lesson #{lesson.position}",
    description: "Review test for words in this lesson.",
    duration: 30,
    max_attempts: 3
  })
  test_component = create_record(Component, {
    lesson: lesson,
    component_type: :test,
    test: test,
    index_in_lesson: words_for_lesson.size
  })

  words_for_lesson.each do |word|
    question_content = "What is the meaning of \"#{word.content}\"?"
    question = create_record(Question, {
      test: test,
      content: question_content,
      question_type: :single_choice
    })
    next unless question

    create_record(Answer, { question: question, content: word.meaning, correct: true })

    (1..3).each do
      fake_word = words.sample
      next if fake_word.meaning == word.meaning
      create_record(Answer, { question: question, content: fake_word.meaning, correct: false })
    end
  end
  lesson_words[lesson.id] = words_for_lesson
  lesson_tests[lesson.id] = test_component
end
puts "----------------------------"

# BƯỚC 6: Ghi danh người dùng vào các khóa học và bài học ngẫu nhiên
puts "Enrolling users in random courses and lessons..."
users.each do |user|
  # Chọn ngẫu nhiên 3 đến 5 khóa học cho mỗi người dùng
  # Bạn có thể thay đổi số lượng này tùy ý
  random_courses = courses.sample(rand(3..5))

  random_courses.each do |course|
    # Ghi danh người dùng vào khóa học đã chọn
    user_course = create_record(UserCourse, {
      user: user,
      course: course,
      enrolment_status: :in_progress,
      progress: 0,
      reason: Faker::Lorem.sentence(word_count: 6),
      start_date: Date.today - rand(1..10).days,
      end_date: nil
    })

    if user_course
      # Ghi danh người dùng vào tất cả bài học của khóa học đã chọn
      # hoặc bạn có thể chọn ngẫu nhiên một số bài học nếu muốn
      course.lessons.each do |lesson|
        create_record(UserLesson, {
          user: user,
          lesson: lesson,
          status: :incomplete,
          grade: 0
        })
      end
    end
  end
end
puts "----------------------------"

# BƯỚC 7: Giả lập kết quả test và đánh dấu từ vựng đã học
puts "Simulating test results and marking words as learned..."
users.each do |user|
  lessons.each do |lesson|
    test_component = lesson_tests[lesson.id]
    next unless test_component

    mark = Faker::Number.between(from: 0, to: 100)
    status = mark >= 80 ? :passed : :failed

    test_result = create_record(TestResult, {
      user: user,
      component: test_component,
      attempt_number: 1,
      user_answers: "{}",
      mark: mark,
      status: status
    })
    next unless test_result

    user_lesson = UserLesson.find_by(user: user, lesson: lesson)
    if user_lesson
      user_lesson.update!(
        grade: mark,
        status: status == :passed ? :completed : :incomplete,
        completed_at: status == :passed ? Time.now : nil
      )
    end

    if status == :passed
      words_for_lesson = lesson_words[lesson.id]
      if words_for_lesson
        words_for_lesson.each do |word|
          word_component = Component.find_by(lesson: lesson, word: word)
          create_record(UserWord, { user: user, component: word_component }) if word_component
        end
      end
      puts "-- User #{user.id} passed test for lesson #{lesson.id} and learned all words."
    else
      puts "-- User #{user.id} failed test for lesson #{lesson.id}."
    end
  end
end
puts "----------------------------"
puts "Fake data seeding complete!"
