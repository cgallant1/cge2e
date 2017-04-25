require "data_mapper"
require "sinatra"

DataMapper::Logger.new($stdout, :debug)
# A MySQL connection:
DataMapper.setup(:default, 'mysql://root:@localhost/e2e')
# Globally across all models and raise exceptions 
DataMapper::Model.raise_on_save_failure = true

class App
	include DataMapper::Resource

	property :id, 			Serial #primary key
	property :project_id, 	String,						:length => 6 # The App unique ID
	property :app_name,		String,						:length => 128
	# property :app_des,		String
	property :app_alias,	String
	property :l2_owner, 	String # The APP's owner
	property :l3_owner,		String
	property :create_by, 	String # Who create the APP
	property :create_at, 	DateTime #When create the APP

	has n, :appFlowRels
	has n, :testCaseDetails
	has n, :solo_case_headers
 	#has n, :flows, :through => Resource
end

class Users
	include DataMapper::Resource

	property :id,			Serial
	property :username,		String
	property :password, 	String
end

class Flow
	include DataMapper::Resource

	property :id,			Serial
	property :flow_name, 	String,					:length => 1024
	property :flow_des,		String,					:length => 1024
	property :create_by,	String
	property :create_at,	DateTime

	# has n, :flow_modules
	has n, :app_flow_rels
	has n, :test_case_headers
	#has n, :apps, :through => Resource
end

# class FlowModule
# 	include DataMapper::Resource

# 	property :id,			Serial
# 	property :module_name,	String
# 	property :module_domain,String
# 	property :module_des,	Text
# 	property :exe_type,		String
# 	property :create_by,	String
# 	property :create_at, 	DateTime

# 	belongs_to :flow
# end

class AppFlowRel
	include DataMapper::Resource

	property :id,			Serial
	property :app_flow_des,	Text
	property :sequence_id, 	Integer
	property :create_by,	String
	property :create_at, 	DateTime
	belongs_to :app
	belongs_to :flow
end



class TestCaseHeader
	include DataMapper::Resource

	property :id,		Serial
	property :test_case_name,	String,			:length => 64
	property :project,	String,					:length => 256
	property :ppm_id, 	String
	# property :portfolio,	String
	property :exec_type,	String
	property :test_case_type, 	String
	property :hyperlink, 	Text
	property :owner, 	String
	property :created_by, 	String
	property :last_modified_by, 	String
	property :last_modified_time, 	DateTime
	property :temp_flow, Boolean, :default  => false
	# property :flow_id, 	Integer
	has n, :test_case_details
	belongs_to :flow
	# has n, :test_case_steps
	#has n, :testCaseDetails
end

class TestCaseDetail
	include DataMapper::Resource

	property :id,	Serial
	property :sequence_id,	Integer
	#property :test_case_id,		Integer
	property :project_id,	String,				:length => 140
	property :environment_box,	String
	property :business_process,	String,			:length => 256
	property :covered_type, 	String,			:length => 256
	property :company_code, 	String,			:length => 256
	property :portfolio,	String,				:length => 64

	belongs_to :app
	belongs_to :test_case_header
	belongs_to  :solo_case_header
end

class SoloCaseHeader
	include DataMapper::Resource

	property :id,	Serial
	property :solo_case_name,	String,			:length => 125

	belongs_to :app
	has n, :test_case_details
	has n, :solo_case_steps
end

class SoloCaseStep
	include DataMapper::Resource

	# property :test_case_id,		Integer
	property :id,	Serial
	property :step_id,	Integer
	property :step_description,	String,			:length => 2014
	property :expected_result,	String,			:length => 1024
	property :memo,	String,						:length => 128
	property :process_name, 	String,			:length => 125
	property :data_input, String,				:length => 512
	# property :attached_image, image

	belongs_to :solo_case_header
end



# class Person
#   include DataMapper::Resource
#   property :id, Serial
#   has n, :tasks
# end

# class Task
#   include DataMapper::Resource
#   property :id, Serial
#   belongs_to :person
# end

# DataMapper.auto_migrate!
# DataMapper.finalize
##App.auto_migrate!
DataMapper.auto_upgrade!