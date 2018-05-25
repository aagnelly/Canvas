###################################################################################################
#                                                                                                 #
#	D/E report returns a csv document with 4 fields for students with a                       #
#	current grade lower than 70%:                                                             #
#	Student name, course name, current grade, URL to the student's grade page_count           #
#	Before running the script, update line 16-20 with the values for your instance and search #
###################################################################################################

# import gems
require 'typhoeus'
require 'link_header'
require 'json'
require 'csv'

####UPDATE THE 5 FIELDS BELOW FOR YOUR INSTANCE#####
$canvas_url = 'https://XXXXXX.instructure.com' 
$canvas_token = ''
enrollment_term_id = ''  #update to current term id
account = '1'	#1 by default to search the root account. If searching a subaccount, update value
$grading_period_id = ''   #grading period id. If your institution does not use grading periods, leave field empty

time = Time.new
date = "#{time.month}.#{time.day}.#{time.year}"
$output_csv = "DE_report.#{date}.csv"
$api_endpoint_account_courses = "/api/v1/accounts/#{account}/courses?enrollment_term_id=#{enrollment_term_id}"  	#pull current term courses
$api_endpoint_courses ='/api/v1/courses/'
curr_courses = Array.new

def get_DE(course_id, course_name)
#reset counters and look for student enrollments with current_score < 70
	enrollment_request_url = "#{$canvas_url}#{$api_endpoint_courses}#{course_id}/enrollments" 
	student_count = 0
	enrollment_page_count = 0
	more_students = true
	
	while more_students # while more_students is true keep looping through the data
		 enrollment_page_count += 1
		 get_enrollments = Typhoeus::Request.new(
			 enrollment_request_url, 
			 method: :get,
			 headers: { authorization: "Bearer #{$canvas_token}" },
			 params: {
				"type" => "StudentEnrollment",
				"grading_period_id" => "#{$grading_period_id}"
				}
			)

		 get_enrollments.on_complete do |response|
			 #get next link
			 links = LinkHeader.parse(response.headers['link']).links
			 next_link = links.find { |link| link['rel'] == 'next' } 
			 enrollment_request_url = next_link.href if next_link 
			 if next_link && "#{response.body}" != "[]"
				more_students = true
			 else
				more_students = false
			 end
			 #ends next link code

		 if response.code == 200
			 student_data = JSON.parse(response.body)
			 student_data.each do |enrollments|
				 grade = enrollments['grades'] #nested grades JSON in response
				 user = enrollments['user']		#nested user JSON
				 # stores current courses to curr_courses array if in current term (FY 2017-2018)
				 if grade['current_score'].to_i < 70 && grade['current_score'] != nil
					 student_count += 1
					 CSV.open($output_csv, 'a') do |csv|
						#csv << [course[1], user['name'], grade['current_score'], grade['html_url']]
						csv << [course_name, user['name'], grade['current_score'], grade['html_url']]
					 end				 
					 end
				 end
		 else
			puts "Something went wrong! Response code was #{response.code}"
		 end
	 end
	 get_enrollments.run
	 
	end
	
end



CSV.open($output_csv, 'wb') do |csv|
    csv << ["course", "student", "current grade", "link to grades"]
end

puts "Report is running. This may take a few minutes . . . "

request_url = "#{$canvas_url}#{$api_endpoint_account_courses}" 
count = 0
page_count = 0
more_data = true
while more_data # while more_data is true keep looping through the data
	 page_count += 1
	 get_courses = Typhoeus::Request.new(
		 request_url, 
		 method: :get,
		 headers: { authorization: "Bearer #{$canvas_token}" }
		)

	 get_courses.on_complete do |response|
		 #get next link
		 links = LinkHeader.parse(response.headers['link']).links
		 next_link = links.find { |link| link['rel'] == 'next' } 
		 request_url = next_link.href if next_link 
		 if next_link && "#{response.body}" != "[]"
			more_data = true
		 else
			more_data = false
	 end
	 #ends next link code

	 if response.code == 200
		 course_data = JSON.parse(response.body)
		 course_data.each do |courses|
		 # stores current courses to curr_courses array if in current term (FY 2017-2018)
			 count += 1
			 get_DE(courses['id'],courses['name'])
		 end
	 else
		puts "Something went wrong! Response code was #{response.code}"
	 end


	 end
get_courses.run
end

puts "Report is complete. Filename: #{$output_csv}"






