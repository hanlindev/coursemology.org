require 'factory_girl'

FactoryGirl.define do
  factory :user do
    name "user"
    email "user@test.com"
    password "foobar"
    password_confirmation "foobar"
    after(:build) do |user|
      user.confirmed_at = Time.now.to_s[0..-7]
    end
  end

  factory :admin, parent: :user do
    name "admin"
    email "admin@example.org"
    after(:build) do |user|
      user.system_role_id = 1
      #user.confirmed_at = Time.now.to_s[0..-7]
    end
  end

  factory :student, parent: :user do
    name "student"
    email "student@example.org"
    after(:build) do |user|
      user.system_role_id = 5
    end
  end


  factory :lecturer, parent: :user do
    name "lecturer"
    email "lecturer@example.org"
    after(:build) do |user|
      user.system_role_id = 3
    end
  end


  factory :course do
    title "Programming"
    description "It's a programming course"
    start_at Time.now.to_s[0..-7]
    end_at 1.day.from_now.to_s[0..-7]
  end

  factory :training, class: Assessment do
    title "Dummy training"
    description "It's a programming training"
    exp 100
    bonus_exp 100
    as_assessment_type = Assessment::training
    
    factory :ongoing_training do
      open_at Time.now.to_s[0..-7]
      bonus_cutoff_at 1.day.from_now.to_s[0..-7]
    end

    factory :overdue_training do
      open_at 3.day.ago.to_s[0..-7]
      bonus_cutoff_at 2.day.ago.to_s[0..-7]
    end

    factory :no_bonus_training do
      open_at 2.day.ago.to_s[0..-7]
      bonus_cutoff_at 1.day.ago.to_s[0..-7]
    end
  end
end
