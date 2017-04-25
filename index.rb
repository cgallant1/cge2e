# encoding: utf-8
require "data_mapper"
require "sinatra"
$LOAD_PATH.unshift(File.dirname(__FILE__))
require "controller/appcontrollers"
require "erb"
require "json"
require "cgi"

get '/environment' do
	if settings.development?
		"development!"
	else
		"not development!"
	end
end

get "/login" do
	erb :login
end

# submit the Json data
get "/submitjson/:appname" do
	conditions = params[:appname]
	conditions = conditions.split("|")

	# Loop through each app and replace special characters
	conditions.each { |condition| 
		condition.gsub! '¶', '/'
		condition.gsub! 'Ð', '.'
		
	}
	puts '***********************************************'
	puts conditions.inspect
	puts '***********************************************'


	appHandler = AppHandler.new
	@apps = appHandler.view_spec_apps(conditions)
	@myJson = JSON.generate(@apps)
	# erb :json
end

get "/submitDialogFlow/:flow_name" do
	conditions = params[:flow_name]
	# conditions = conditions.split("|")

	p = CGI.parse(conditions)
	flow_name = p['flow_name'].first
	fName_conditions = flow_name.split("|")
	
	appHandler = AppHandler.new
	@flows = Flow.all()
	@flows = appHandler.view_spec_flows_by_FlowName(fName_conditions) if fName_conditions.length > 0

	# Sort the Flows
	@flows.sort_by!{ |m| m.id }
	@flows.reverse!
	# @flows = @flows.flatten
	@flows = @flows.uniq

	@myJson = JSON.generate(@flows)
	# erb :json
end

get "/submitFlowID/:flow_id" do
	conditions = params[:flow_id]

	p = CGI.parse(conditions)
	flow_id = p['flow_id'].first

	appHandler = AppHandler.new
	@flowRels = AppFlowRel.all(:flow_id => flow_id)

	@flowRels.sort_by!{ |m| m.id }
	@flowRels = @flowRels.uniq

	@myJson = JSON.generate(@flowRels)
end

get "/submitFlow/:flow_name" do
	conditions = params[:flow_name]
	# conditions = conditions.split("|")

	p = CGI.parse(conditions)
	flow_name = p['flow_name'].first
	app_name = p['app_name'].first
	com_code = p['com_code'].first
	ppm_id = p['ppm_id'].first
	portfolio = p['portf'].first
	env_box = p['env_box'].first
	key_doc = p['key_doc'].first
	biz_proc = p['biz_proc'].first
	e2e_case = p['e2e_case'].first

	fName_conditions = flow_name.split("|")
	aName_conditions = app_name.split("|")
	coCode_conditions = com_code.split("|")
	ppmId_conditions = ppm_id.split("|")
	portf_conditions = portfolio.split("|")
	envbox_conditions = env_box.split("|")
	keyDoc_conditions = key_doc.split("|")
	bizProc_conditions = biz_proc.split("|")
	e2eCase_conditions = e2e_case.split("|")
	
	appHandler = AppHandler.new
	@flows = Flow.all()
	@flows = appHandler.view_spec_flows_by_FlowName(fName_conditions) if fName_conditions.length > 0
	@flows = @flows & appHandler.view_spec_flows_by_AppName(aName_conditions) if aName_conditions.length > 0
	@flows = @flows & appHandler.view_spec_flows_by_ComCode(coCode_conditions) if coCode_conditions.length > 0
	@flows = @flows & appHandler.view_spec_flows_by_PPMID(ppmId_conditions) if ppmId_conditions.length > 0
	@flows = @flows & appHandler.view_spec_flows_by_Portfolio(portf_conditions) if portf_conditions.length > 0
	@flows = @flows & appHandler.view_spec_flows_by_EnvBox(envbox_conditions) if envbox_conditions.length > 0
	@flows = @flows & appHandler.view_spec_flows_by_KeyDoc(keyDoc_conditions) if keyDoc_conditions.length > 0
	@flows = @flows & appHandler.view_spec_flows_by_BizProc(bizProc_conditions) if bizProc_conditions.length > 0
	@flows = @flows & appHandler.view_spec_flows_by_E2ECase(e2eCase_conditions) if e2eCase_conditions.length > 0

	# puts '@@@@@@@@@@@@@@@@@@/submitFlow/:flow_name@@@@@@@@@@@@@@@@@@@@@'
	# puts @flows.inspect
	# puts '@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@'

	# Sort the Flows
	@flows.sort_by!{ |m| m.flow_des.downcase }
	# @flows = @flows.flatten
	@flows = @flows.uniq

	@myJson = JSON.generate(@flows)
	# erb :json
end

get '/emptyflowsearch/:flow_name' do
	conditions = params[:flow_name]

	p = CGI.parse(conditions)
	flow_name = p['flow_name'].first
	app_name = p['app_name'].first

	fName_conditions = flow_name.split("|")
	aName_conditions = app_name.split("|")

	adapter = DataMapper.repository(:default).adapter
	sql = "SELECT flow_des FROM flows  
	INNER JOIN app_flow_rels ON app_flow_rels.flow_id = flows.id 
	INNER JOIN apps ON apps.id = app_flow_rels.app_id
	WHERE NOT EXISTS (SELECT 1 FROM test_case_headers WHERE test_case_headers.flow_id = flows.id)"

	# build the rest of the query
	counter = 1
	fName_conditions.each do |condition|
		if counter == 1
			sql += " AND (flow_name LIKE '%#{condition}%'"
		else
			sql += " Or flow_name LIKE " + "'%#{condition}%'"
		end
		counter += 1
	end
	sql += ")" if fName_conditions.length > 0

	counter = 1
	aName_conditions.each do |condition|
		if counter == 1
			sql += " AND ((apps.app_name LIKE '%#{condition}%' OR apps.project_id LIKE '%#{condition}%')"
		else
			sql += " Or (apps.app_name LIKE '%#{condition}%' OR apps.project_id LIKE '%#{condition}%')"
		end
		counter += 1
	end
	sql += ")" if aName_conditions.length > 0

	sql += " ORDER BY flow_des"

	puts '##############################################'
	puts sql
	puts '##############################################'

	@result = adapter.select(sql)

	# Convert to a form that can be combined with the other search results
	# conv_result = []
	# @result.each { |item| 
	# 	conv_result.push(Hash["flow_des", item, "id", "", "test_case_name", "", "test_case_type", ""])
	# 	# Hash["a", 100, "b", 200]
	# }
	# conv_result = conv_result.flatten.uniq
	@result = @result.flatten.uniq

	# puts '##############################################'
	# puts conv_result.inspect
	# puts '##############################################'	

	@myJson = JSON.generate(@result)
end

def SCB(str)
	# change the symbol back from javascript ---- Casper
	str = str.gsub(/Ð/ , '/')
	str = str.gsub(/Ø/ , '?')
	str = str.gsub(/Ò/ , '\\')
	str = str.gsub(/Á/ , '&')
	str = str.gsub(/Ý/ , '%')
	str = str.gsub(/Ñ/ , '#')
	str = str.gsub(/Ê/ , '[')
	str = str.gsub(/Ë/ , ']')
	str = str.gsub(/Æ/ , '|')
	str = str.gsub(/β/ , '&')
	str = str.gsub(/Δ/ , '*')
	str = str.gsub(/Þ/ , '.')
end

get '/mastersearch/:flow_name' do
	conditions = params[:flow_name]
	p = CGI.parse(conditions)
	# change the sybol back in each field ---- Casper
	flow_name = SCB(p['flow_name'].first)
	app_name = SCB(p['app_name'].first)
	com_code = SCB(p['com_code'].first)
	ppm_id = SCB(p['ppm_id'].first)
	portfolio = SCB(p['portf'].first)
	env_box = SCB(p['env_box'].first)
	key_doc = SCB(p['key_doc'].first)
	biz_proc = SCB(p['biz_proc'].first)
	e2e_case = SCB(p['e2e_case'].first)

	fName_conditions = flow_name.split("|")
	aName_conditions = app_name.split("|")
	coCode_conditions = com_code.split("|")
	ppmId_conditions = ppm_id.split("|")
	portf_conditions = portfolio.split("|")
	envbox_conditions = env_box.split("|")
	keyDoc_conditions = key_doc.split("|")
	bizProc_conditions = biz_proc.split("|")
	e2eCase_conditions = e2e_case.split("|")

	adapter = DataMapper.repository(:default).adapter
	sql = "SELECT DISTINCT flow_des, test_case_headers.id, test_case_name, test_case_type FROM `test_case_headers`
	INNER JOIN flows ON flows.id = test_case_headers.flow_id 
	INNER JOIN test_case_details ON test_case_details.test_case_header_id = test_case_headers.id
	INNER JOIN apps ON apps.id = test_case_details.app_id
	WHERE temp_flow = 0"

	# Build the rest of the query for other search parameters
	counter = 1
	fName_conditions.each do |condition|
		if counter == 1
			sql += " AND (flow_name LIKE '%#{condition}%'"
		else
			sql += " Or flow_name LIKE " + "'%#{condition}%'"
		end
		counter += 1
	end
	sql += ")" if fName_conditions.length > 0

	counter = 1
	aName_conditions.each do |condition|
		if counter == 1
			sql += " AND ((apps.app_name LIKE '%#{condition}%' OR apps.project_id LIKE '%#{condition}%')"
		else
			sql += " Or (apps.app_name LIKE '%#{condition}%' OR apps.project_id LIKE '%#{condition}%')"
		end
		counter += 1
	end
	sql += ")" if aName_conditions.length > 0

	counter = 1
	coCode_conditions.each do |condition|
		if counter == 1
			sql += " AND (company_code LIKE '%#{condition}%'"
		else
			sql += " Or company_code LIKE " + "'%#{condition}%'"
		end
		counter += 1
	end
	sql += ")" if coCode_conditions.length > 0

	counter = 1
	ppmId_conditions.each do |condition|
		if counter == 1
			sql += " AND (ppm_id LIKE '%#{condition}%'"
		else
			sql += " Or ppm_id LIKE " + "'%#{condition}%'"
		end
		counter += 1
	end
	sql += ")" if ppmId_conditions.length > 0

	counter = 1
	portf_conditions.each do |condition|
		if counter == 1
			sql += " AND (portfolio LIKE '%#{condition}%'"
		else
			sql += " Or portfolio LIKE " + "'%#{condition}%'"
		end
		counter += 1
	end
	sql += ")" if portf_conditions.length > 0

	counter = 1
	envbox_conditions.each do |condition|
		if counter == 1
			sql += " AND (environment_box LIKE '%#{condition}%'"
		else
			sql += " Or environment_box LIKE " + "'%#{condition}%'"
		end
		counter += 1
	end
	sql += ")" if envbox_conditions.length > 0

	counter = 1
	keyDoc_conditions.each do |condition|
		if counter == 1
			sql += " AND (covered_type LIKE '%#{condition}%'"
		else
			sql += " Or covered_type LIKE " + "'%#{condition}%'"
		end
		counter += 1
	end
	sql += ")" if keyDoc_conditions.length > 0

	counter = 1
	bizProc_conditions.each do |condition|
		if counter == 1
			sql += " AND (business_process LIKE '%#{condition}%'"
		else
			sql += " Or business_process LIKE " + "'%#{condition}%'"
		end
		counter += 1
	end
	sql += ")" if bizProc_conditions.length > 0

	counter = 1
	e2eCase_conditions.each do |condition|
		if counter == 1
			sql += " AND (test_case_name LIKE '%#{condition}%'"
		else
			sql += " Or test_case_names LIKE " + "'%#{condition}%'"
		end
		counter += 1
	end
	sql += ")" if e2eCase_conditions.length > 0

	sql += " ORDER BY flow_des"

	puts '##############################################'
	puts sql
	puts '##############################################'

	# Run the SQL statement
	@result = adapter.select(sql)	

	# Convert from a Struct array to a Hash array to be more easily consumed by JSP
	conv_result = []
	@result.each { |item| 
		conv_result.push(Hash[item.each_pair.to_a])
	}
	conv_result = conv_result.flatten.uniq	

	# Get flows without E2E Test Cases 
	appHandler = AppHandler.new
	test_result = []
	emptyFlows = []
	# Only get empty flows if there are no unsuitable parameters
	if coCode_conditions.length == 0 and ppmId_conditions.length == 0 and ppmId_conditions.length == 0 and portf_conditions.length == 0 and envbox_conditions.length == 0 and keyDoc_conditions.length == 0 and bizProc_conditions.length == 0 and e2eCase_conditions.length == 0
		emptyFlows = appHandler.getEmptyFlows(flow_name, app_name)
	end

	# test_result << emptyFlows
	test_result << conv_result
	test_result = test_result.flatten

	# Loop through empty flows check if they exist in the other resulsts (A > B > C,  A > A > B > C)
	emptyFlowsFiltered = []
	# puts '^v^v^v^v^v^v^v^v^v^v^v^v^v^v^v^v^v^v^v^v^v^v'
	emptyFlows.each { |item|
		if test_result.find { | h | h[:flow_des] == item[:flow_des]}
			# puts item[:flow_des]
		else
			test_result << item
		end
	}
	# puts '^v^v^v^v^v^v^v^v^v^v^v^v^v^v^v^v^v^v^v^v^v^v'

	test_result = test_result.uniq.flatten

	# Sort first by flow_des then by test_case_name
	# test_result.sort_by!{ |m| m[:flow_des].downcase, m[:test_case_name].downcase }
	test_result.sort! { |test_result, b| [test_result[:flow_des].downcase, test_result[:test_case_name].downcase] <=> [b[:flow_des].downcase, b[:test_case_name].downcase]}

	# puts '+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
	# puts test_result.inspect
	# puts '+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'

	@myJson = JSON.generate(test_result)
end

get "/submitTC/:flow_id" do
	conditions = params[:flow_id]
	#conditions = conditions.split("|")

	p = CGI.parse(conditions)
	flow_id = p['flow_id'].first
	com_code = p['com_code'].first
	ppm_id = p['ppm_id'].first
	portfolio = p['portf'].first
	env_box = p['env_box'].first
	key_doc = p['key_doc'].first
	biz_proc = p['biz_proc'].first
	e2e_case = p['e2e_case'].first

	id_conditions = flow_id.split("|")
	coCode_conditions = com_code.split("|")
	ppmId_conditions = ppm_id.split("|")
	portf_conditions = portfolio.split("|")
	envbox_conditions = env_box.split("|")
	keyDoc_conditions = key_doc.split("|")
	bizProc_conditions = biz_proc.split("|")
	e2eCase_conditions = e2e_case.split("|")

	appHandler = AppHandler.new
	@tc = appHandler.view_spec_tc(id_conditions, coCode_conditions, ppmId_conditions,portf_conditions, envbox_conditions, keyDoc_conditions, bizProc_conditions, e2eCase_conditions)

	# Sort the test cases
	@tc.sort_by!{ |m| m.test_case_name.downcase }

	@myJson = JSON.generate(@tc)
	# erb :json
end

get "/submitOTC/:ppm_id" do
	conditions = params[:ppm_id]
	#conditions = conditions.split("|")

	p = CGI.parse(conditions)
	ppm_id = p['ppm_id'].first
	e2e_case = p['e2e_case'].first

	ppmId_conditions = ppm_id.split("|")
	e2eCase_conditions = e2e_case.split("|")

	appHandler = AppHandler.new
	@tc_TempFlow = appHandler.view_orphan_tc(ppmId_conditions, e2eCase_conditions)

	# Sort the test cases
	@tc_TempFlow.sort_by!{ |m| m.test_case_name.downcase }

	@myJson = JSON.generate(@tc_TempFlow)
	# erb :json
end

#initial the data to load into Database
get "/loadexcel" do
	require 'mysql'
	appHandler = AppHandler.new
	appHandler.read_excel('\ruby.xlsx')
end

#Create temp data to be used on mapping/creation  !!!NEEDS 1 app in the DB
get "/loadtempdata" do
	#Flow.create(id:1,:flow_name =>'TEMP DATA',:flow_des=>'TEMP DATA',:create_by=>'SYSTEM',:create_at=>Time.now)
	SoloCaseHeader.create(id:1,:solo_case_name=>'TEMP DATA',:app_id=>1)
	return "Loading default data succeeded! <a href='/main'>back to main page</a>"
end

get "/fillexistingflowdes" do
	flowParts = []

	# Build a condensed flow and update the table
	@flows = Flow.all()
	@flows.each { |flow|
		summFlow = ""
		lastFlow = ""
		fullName = flow.flow_name.strip
		flowParts = fullName.split(' > ')
		flowParts.each do |part|
			if lastFlow == ""
				lastFlow = part
				summFlow = part
			elsif lastFlow != part
				lastFlow = part
				summFlow = summFlow + ' > ' + part
			end
		end
		flow.update(:flow_des => summFlow)
	}

	return "Sucessfully filled in the condensed flow to for Flow table."
end

post "/searchcondition" do
	# puts "I am here >>>>>>>>>"
	conditions = params[:searchcondition]
	# puts conditions
	conditions = conditions.split("|")
	appHandler = AppHandler.new
	@flows = appHandler.search_condition(conditions)
	# @list = JSON.generate(appHandler.search_condition(conditions))
	erb :viewflow
end

get "/searchflows/:app_name" do
	appHandler = AppHandler.new
	# conditions = params[:searchcondition]
	conditions = params[:app_name]
	p = CGI.parse(conditions)
	app_name = p['app_name'].first
	# puts "condition的值为"
	# puts conditions
	# @flows = JSON.generate(appHandler.searchSpecificFlow(params[:searchcondition]))
	@flows = appHandler.searchSpecificFlow(app_name)
	# puts '^^^^^^^^^^^^^^^^^^^^^^APP SEARCH^^^^^^^^^^^^^^^^^^^^'
	# puts @flows.inspect
	# puts '^^^^^^^^^^^^^^^^^^^^^^APP SEARCH^^^^^^^^^^^^^^^^^^^^'

		# Sort the Flows
	@flows.sort_by!{ |m| m.flow_des.downcase }
	# @flows = @flows.flatten
	@flows = @flows.uniq

	@myJson = JSON.generate(@flows)
	# puts @flows.inspect
	# @list = appHandler.viewFlow()
	# @apps = appHandler.viewApp()
	# erb :viewflow
end

get "/main" do
	appHandler = AppHandler.new
	@list = appHandler.viewFlow()
	# @flows = JSON.generate(appHandler.viewAllModules())
	@flows = appHandler.viewAllModules()

	@apps = appHandler.viewApp(12)
	erb :demo
end
#do login
post "/login" do
	username = params[:username]
	password = params[:password]
	appHandler = AppHandler.new
	status = appHandler.login(username, password)
	puts status
	if status 
		redirect to("/main")
	else
		redirect to("/login")
	end
end

# get "/search/:appname" do
# 	# appHandler = AppHandler.new
# 	# @flow = appHandler.searchSpecificFlow(params[:appname])
# 	# puts @flow.inspect
# 	erb:search
# end

get "/" do
	redirect to("/main")
end

delete "/app/:id" do
	id = params[:id]
	appHandler = AppHandler.new
	@apps = appHandler.deleteApp(id)
	puts @apps
	redirect to("/viewflow")
end

put "/app/:id" do
	id = params[:id]
	appHandler = AppHandler.new
	@apps = appHandler.updateApp(id)
	redirect to("/viewapp/"+id)
end



# get "/droplist" do
# 	appHandler = AppHandler.new
# 	@apps = appHandler.viewApp(10)
# 	erb :droplist
# end

get "/createapp" do
	erb :appcreate
end

post "/docreateapp" do
	p params[:app_data]
	appname = ""
	projectid = ""	
	appalias = ""
	l2owner = ""
	l3owner = ""
	createby = ""

	#Throw the ruby exception error message using begin_rescue_end --- Joseph
	begin
		params[:app_data].each_value do |item|
			item.each_key do |subitem|
				item.each_value do |subitems|
					subitems.each_value do |sub|
						appname = sub[:appname]
						projectid = sub[:projectid]
						appalias = sub[:appalias]
						# portfolio = sub[:t_portfolio]
						l2owner = sub[:l2owner]
						l3owner = sub[:l3owner]
						createby = sub[:createby]
					end

					newApp = App.create(:app_name =>appname,:project_id =>projectid,:app_alias =>appalias,:l2_owner =>l2owner,:l3_owner =>l3owner,:create_by =>createby,:create_at => Time.now)			
					return newApp[:id].to_json
				end
			end
		end

	rescue =>error
		status 500
		error_1="Ruby Error #{error.class}"+"Ruby Error #{$!} Ruby Error#{$@}"
	end
end

get "/viewfullapplist" do
	appHandler = AppHandler.new
	@apps = JSON.generate(appHandler.viewApp(12))
end

get "/viewallapps" do
	appHandler = AppHandler.new
	@apps = JSON.generate(App.all())
end

get "/viewallflow" do
	appHandler = AppHandler.new
	@flows = JSON.generate(appHandler.viewFlow())
end

get "/createflow" do
	appHandler = AppHandler.new
	@apps = App.all(:order => [ :project_id.asc ])
	erb :flowcreate
end

post "/createflow" do
	flowname = params[:flowname]
	flowdes = params[:flowdes]
	createby = params[:createby]
	apps = params[:apps]
	# puts apps
	i = 1
	#throw the ruby exception error message to the web page using begin_rescue_end --- Joseph
	begin
		appArray = Hash.new
		apps.each do |app|
			apps = App.all(:id => app)
			apps = apps.flatten
			flowname = flowname + apps[0].app_name + " > "
			appArray["#{i}"]= app
			i+=1
			# puts i
		end

		appHandler = AppHandler.new
		flowname = flowname[0..flowname.length - 4]
		flowdes = appHandler.condensedFlowName(flowname)
		# appArray = [app1,app2,app3]

		# appArray = {"1"=>app1,"2"=>app2,"3"=>app3}
		puts appArray.inspect
		appHandler = AppHandler.new
		flow = appHandler.createAppFlow(flowname,flowdes,appArray,createby)

		return flow.to_json

	rescue =>error
		status 500
		error_1="Ruby Error #{error.class}"+"Ruby Error #{$!} Ruby Error#{$@}"
	end
end

get "/appflowcreate" do
	#@appid = params[:appid]
	appHandler = AppHandler.new
	appHandler.createAppFlow()
end

# post "/viewflows" do
# 	appHandler = AppHandler.new
# 	@flows = appHandler.viewFlow()
# 	erb :viewflow
# end

# get "/createmodule" do
# 	appHandler = AppHandler.new
# 	@flows = appHandler.viewFlow()
# 	erb:modulecreate
# end

post "/docreatemodule" do
	moduleArr = {"modulename"=>params[:modulename],
				 "moduledes"=>params[:moduledes],
				 "flowid"=>params[:flowid],
				 "createby"=>params[:createby],
				 "moduletype"=>params[:moduleype]
	}
	appHandler = AppHandler.new
	appHandler.createModule(moduleArr)
end

# 用于手动创建module到已知的flow
get "/createmodule/:id" do
	appHandler = AppHandler.new
	appHandler.mannualAddModule(params[:id])
	# puts "创建module到flow id=1成功"
end

# get "/viewapp/:id" do
# 	@flowid = params[:id].to_i
# 	appHandler = AppHandler.new
# 	@app = appHandler.viewFlowApp(@flowid)
# 	erb :viewapp
# end

get "/getapp/:id" do
	@appID = params[:id].to_i
	# @app = App.all(:id => @flow_id)

	@apps = App.all(:id => @appID)
	@apps = @apps.flatten.uniq

	# puts 'HHHHHHHHHHHHHHHHHH Get App HHHHHHHHHHHHHHHHHHHHHHH'
	# puts @appID
	# puts @apps.inspect
	# puts 'HHHHHHHHHHHHHHHHHH Get App HHHHHHHHHHHHHHHHHHHHHHH'

	@myJson = JSON.generate(@apps)
end

# get "/viewmodule/:id" do
# 	@flowid = params[:id].to_i
# 	appHandler = AppHandler.new
# 	@modules = appHandler.viewFlowModule(@flowid)
# 	puts @modules
# 	erb :viewmodule
# end

post "/docreateheader" do
	p params[:big_data]
	test_case_name = ""
	project_name = ""
	ppm_id = ""
	exec_type = ""
	test_case_type = ""
	hyperlink = ""
	owner = ""

	seq_id = ""
	project_id = ""
	enviroment = ""
	biz_process = ""
	covered_type = ""
	company_code = ""
	portfolio = ""
	app_id = ""
	solo_case_id = ""

	case_name = ""
	step_id = ""
	proc_name = ""
	step_desc = ""
	data_input = ""
	expec_result = ""
	memo = ""
	step_app_id = ""

	solo_h_id = ""
	sc_id = ""
	h_id = ""
	id = ""
	header_id = ""

	mapflowList = Array.new
	flowList = Array.new
	mappedFlowID = ""
	newName = ""
	newSMName = ""

	idx = 0

	# Deletion Variables
	details = Array.new
	detailsUpdated = Array.new
	detailsFlow = Array.new
	steps = Array.new
	stepsUpdated = Array.new

	#throw the ruby exception error message to the web page using begin_rescue_end --- Joseph
	begin
		params[:big_data].each_value do |item|
			item.each_key do |subitem|
				if subitem == 'tc_id'
					item.each_value do |subitems|
						subitems.each_value do |sub|
							h_id = sub[:id]
						end
					end
				end

				if subitem == 'header_data' 
					item.each_value do |subitems|
						subitems.each_value do |sub|
							test_case_name = sub[:t_name]
							project_name = sub[:t_product]
							ppm_id = sub[:t_ppmid]
							# portfolio = sub[:t_portfolio]
							exec_type = sub[:t_exectype]
							test_case_type = sub[:t_tctype]
							hyperlink = sub[:t_hyperlink]
							owner = sub[:t_owner]
						end
					end

					if h_id == ""
						header_id = TestCaseHeader.create(
									:flow_id =>1,				# TEMP DATA
									:temp_flow=>true,
									:test_case_name =>test_case_name,
									:project =>project_name,
									:ppm_id =>ppm_id,
									# :portfolio =>portfolio,
									:exec_type =>exec_type,
									:test_case_type =>test_case_type,
									:hyperlink =>hyperlink,
									:owner =>owner,
									:last_modified_time => Time.now
						 		)
						h_id = header_id[:id]
					else
						# doing update in database
						test = TestCaseHeader.first_or_create(:id=>h_id)
						test.update(:test_case_name =>test_case_name,:project =>project_name,:ppm_id =>ppm_id,:exec_type =>exec_type,:test_case_type =>test_case_type,:hyperlink =>hyperlink,:owner =>owner)		
					end
					# Make an array of all the details for this test case for deletion comparison later
					allDetails = TestCaseDetail.all(:test_case_header_id=>h_id)
					allDetails.each do |detail|
						details.push(detail[:id].to_i)
					end		
				end

				if subitem == 'detail_data' 
					item.each_value do |subitems|
						subitems.each_value do |sub|
							id = sub[:id]
							seq_id = sub[:seq_id]
							project_id = sub[:product]
							enviroment = sub[:env]
							biz_process = sub[:biz_proc]
							covered_type = sub[:cov_type]
							company_code = sub[:com_code]
							portfolio = sub[:portfolio]
							app_id = sub[:app_id]

							# Save the apps and sequence to check flow mapping and creation later
							mapflowList.push(seq_id + ',' + app_id)
							flowList.push(app_id)

							arrCombo = project_id.split(' - ')
							newName += arrCombo[1] + ' > '

							# if the record is existing
							if id == nil
								sc_id = ""
								newtcd_id = TestCaseDetail.create(:project_id =>project_id,:environment_box =>enviroment,:business_process=>biz_process,:covered_type=>covered_type,:company_code=>company_code,:portfolio=>portfolio,:sequence_id=>seq_id,:app_id=>app_id,:solo_case_header_id=>1,:test_case_header_id=>h_id)
								detailsUpdated.push(newtcd_id.id.to_i)
							else
								# doing update in database
								test = TestCaseDetail.first_or_create(:id=>id)
								# Get and use the current solocase id on update [ASSUMES THAT NOTHING HAS CHANGED!]
								sc_id = test[:solo_case_header_id]

								test.update(:project_id =>project_id,:environment_box =>enviroment,:business_process=>biz_process,:covered_type=>covered_type,:company_code=>company_code,:portfolio=>portfolio,:sequence_id=>seq_id,:app_id=>app_id,:solo_case_header_id=>sc_id)	
								
								# Make a list of updated records
								detailsUpdated.push(id.to_i)
							end

							# Make an array of all the steps for this test case for deletion comparison later
							# if sc_id != ""
							# 	allSteps = SoloCaseStep.all(:solo_case_header_id=>sc_id)
							# 	allSteps.each do |step|
							# 		steps.push(step[:id].to_i)
							# 	end
							# 	# puts '^v^v^v^v^v^v^v^v^v^v^v^v^v^v^v^v^v^v^v^v^v'
							# 	# puts steps.inspect
							# 	# puts '^v^v^v^v^v^v^v^v^v^v^v^v^v^v^v^v^v^v^v^v^v'
							# end
						end
					end

					# Map the flow id to existing one if it exists
					appHandler = AppHandler.new
					appHandler.mapcreateFlow(mapflowList, flowList, h_id, newName)

					# Clear the arrays
					mapflowList = Array.new
					flowList = Array.new	
					arrCombo = Array.new
					newName = ""
				end

				if subitem == 'step_data' 
					allDetails = TestCaseDetail.all(:test_case_header_id=>h_id)
					allDetails.each do |detail|
						detailsFlow.push(detail[:id].to_i)
					end	
					
					idx = 0
					item.each_value do |subitems|
						subitems.each_value do |sub|
							id = sub[:id]
							seq_id = sub[:seq_id]
							case_name = sub[:case_name]
							step_id = sub[:step_id]
							proc_name = sub[:proc_name]
							step_desc = sub[:step_desc]
							data_input = sub[:data_input]
							expec_result = sub[:expec_res]
							memo = sub[:memo]
							step_app_id = sub[:app_id]

	# puts '^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^'
	# 						detailsUpdated.inspect
	# puts '^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^'

							if id == nil
								# Create the header first for step 1
								if step_id == '1'
									soloHead = SoloCaseHeader.create(:solo_case_name=>case_name,:app_id=>step_app_id)	
									solo_h_id = soloHead[:id]

	# puts '^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^'
	# puts seq_id
	# puts '^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^'

									# Update the Test Case Detail record
									test = TestCaseDetail.first_or_create(:id=>detailsUpdated[seq_id.to_i - 1].to_i)

									# if test[:solo_case_header_id] == 1
									test.update(:solo_case_header_id=>solo_h_id)
									# end

									idx = idx + 1
								end

								# Create the steps
								newstep_id = SoloCaseStep.create(:step_id=>step_id,:step_description=>step_desc,:expected_result=>expec_result,:memo=>memo,:process_name=>proc_name,:data_input=>data_input,:solo_case_header_id=>solo_h_id)
								stepsUpdated.push(newstep_id.id.to_i)
							else
								# Make a list of updated records
								stepsUpdated.push(id.to_i)

								# Update the record in both tables
								step = SoloCaseStep.first_or_create(:id=>id)			
								solo_h_id = step[:solo_case_header_id]

								if step_id == '1'
									stepHead = SoloCaseHeader.first_or_create(:id=>solo_h_id)
									stepHead.update(:solo_case_name=>case_name,:app_id=>step_app_id)

									idx = idx + 1
								end
			
								step.update(:step_id=>step_id,:step_description=>step_desc,:expected_result=>expec_result,:memo=>memo,:process_name=>proc_name,:data_input=>data_input,:solo_case_header_id=>solo_h_id)		
							end
						end
					end
				end
			end
		end
		# Remove Deleted Rows
		detailsToDel = details - detailsUpdated
		detailsToDel.each do |delItem|
			item = TestCaseDetail.all(:id=>delItem)
			TestCaseDetail.get(delItem).destroy
		end
		# Detect deletion of all details
		test = TestCaseHeader.first_or_create(:id=>h_id)
		if TestCaseDetail.count(:test_case_header_id=>h_id) == 0
			test.update(:temp_flow=>true)
		end	

		# Get a list of all the steps related to this E2E Case
		adapter = DataMapper.repository(:default).adapter
		counter = 1
		sql = "SELECT 
		solo_case_steps.id 
		FROM solo_case_steps 
		INNER JOIN solo_case_headers ON solo_case_headers.id = solo_case_steps.solo_case_header_id 
		INNER JOIN test_case_details ON solo_case_steps.solo_case_header_id = test_case_details.solo_case_header_id 
		WHERE test_case_details.id = "

		# build the rest of the query
		detailsUpdated.each do |detail|
			tcd_id = detail

			if counter == 1
				sql += tcd_id.to_s
			else
				sql += " Or test_case_details.id = " + tcd_id.to_s
			end
			counter += 1
		end

		# Get the records
		if counter > 1
			steps = adapter.select(sql)
			steps = steps.flatten.uniq		
		else
			steps = Array.new
		end
		# puts '$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$'
		# puts steps.flatten.inspect
		# puts '$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$'

		# puts '#################################################'
		# puts stepsUpdated.flatten.inspect
		# puts '#################################################'


		# Remove Deleted Step Rows
		# Steps where app is in the flow but not in the step list
		stepsToDel = steps - stepsUpdated
		stepsToDel.each do |delItem|
			item = SoloCaseStep.all(:id=>delItem)
			SoloCaseStep.get(delItem).destroy
		end

		return h_id.to_json

	rescue =>error
		status 500
		error_1="Ruby Error #{error.class}"+"Ruby Error #{$!} Ruby Error#{$@}"
	end
end

get '/testcasemain' do
	appHandler = AppHandler.new
	#@testcase = appHandler.viewTestcaseHeaderAll()

	@flows = Flow.all()
	@testcase = TestCaseHeader.all()

	erb :testcasemain
end

get '/createtestcase' do
	appHandler = AppHandler.new
	@apps = appHandler.viewApp(10)
	@flows = appHandler.viewFlow()
	erb :testcasecreate
end

get '/test_case_edit/:id' do
	solo_steps = []

	@tc_id = params[:id].to_i

	appHandler = AppHandler.new
	@apps = appHandler.viewApp(10)
	@flows = appHandler.viewFlow()
	@testcase = appHandler.viewTestcaseHeader(@tc_id)
	@testcases = appHandler.viewTestcaseHeaderAll()
	@testcasedetails = appHandler.viewTestcaseDetails(@tc_id)

	# @testcasesteps = appHandler.viewTestcaseSteps(@tc_id)

	# puts '&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&'
	# puts @testcasedetails.inspect
	# puts '&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&'


	adapter = DataMapper.repository(:default).adapter

	counter = 1
	sql = "SELECT
		solo_case_steps.id,
		solo_case_steps.step_id,
		solo_case_steps.step_description,
		solo_case_steps.expected_result,
		solo_case_steps.memo,
		solo_case_steps.process_name,
		solo_case_steps.data_input,
		solo_case_headers.solo_case_name,
		solo_case_headers.app_id,
		apps.project_id,
		apps.app_name,
		test_case_details.sequence_id
		FROM
		solo_case_steps
		INNER JOIN solo_case_headers ON solo_case_headers.id = solo_case_steps.solo_case_header_id
		INNER JOIN apps ON solo_case_headers.app_id = apps.id
		INNER JOIN test_case_details ON solo_case_steps.solo_case_header_id = test_case_details.solo_case_header_id
		WHERE
		test_case_details.id = "

	# build the rest of the query
	@testcasedetails.each do |detail|
		# solo_id = detail[:solo_case_header_id]
		tcd_id = detail[:id]

		if counter == 1
			sql += tcd_id.to_s
		else
			sql += " Or test_case_details.id = " + tcd_id.to_s
		end
		counter += 1
	end
	sql += " ORDER BY test_case_details.sequence_id ASC, solo_case_steps.step_id ASC"

	if counter > 1
		solo_steps = adapter.select(sql)
	 # 	puts '$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$'
		# puts solo_steps.flatten.inspect
		# puts '$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$'

		@solo_case_steps = solo_steps.flatten.uniq		
	else
		@solo_case_steps = Array.new
	end


	erb :test_case_edit
end

get '/test_case_edit' do
	appHandler = AppHandler.new
	@testcase = appHandler.viewTestcaseHeader(-1)
	@testcasedetails = appHandler.viewTestcaseDetails(-1)
	# @testcasesteps = appHandler.viewTestcaseSteps(-1)
	erb :test_case_edit
end

get "/searchProjectApp/:projectid&:appname" do
	conditions = params[:projectid]
	p = CGI.parse(conditions)
	projectid = p['projectid'].first

	conditions = params[:appname]
	p = CGI.parse(conditions)
	appname = p['appname'].first
	appname.gsub! '¶', '/'
	appname.gsub! 'Ð', '.'

	# Check if a app already exists for this project id
	count = App.count(:project_id => projectid)
	if count > 0
		return "found".to_json
	else
		# Return the full name
		temp = projectid + ' - ' + appname
		return temp.to_json
	end

	
	# count = JSON.generate(count)
end

get "/searchProjectID/:projectid" do
	conditions = params[:projectid]
	p = CGI.parse(conditions)
	projectid = p['projectid'].first

	# Check if a app already exists for this project id
	count = App.count(:project_id => projectid)

	return count.to_json	
	# count = JSON.generate(count)
end

get "/searchAppName/:appname" do
	conditions = params[:appname]
	p = CGI.parse(conditions)
	appname = p['appname'].first

	appname.gsub! '¶', '/'
	appname.gsub! 'Ð', '.'

	count = App.count(:app_name => appname)

	return count.to_json
	# count = JSON.generate(count)
end

get "/submitFlowName/:flowname" do
	conditions = params[:flowname]
	p = CGI.parse(conditions)
	flow_name = p['flowname'].first
	flow_name.gsub! '¶', '/'
	flow_name.gsub! 'Ð', '.'

	count = Flow.count(:flow_name => flow_name)

	return count.to_json
end

get '/importdata' do
	erb :importData
end

post '/saveimportdata' do
	p params[:import_data]

	updateHeader_id = ''
	updateStep_id = ''
	cur_row = 0
	curStep_row = 0
	casesImported = 0
	casesUpdated = 0

	h_id = ""
	header_id = ""
	ppm_id = ''
	solo_h_id =''

	newName = ""
	mapflowList = Array.new
	flowList = Array.new
	tcdList = Array.new	
	caseList = []

	#throw the ruby exception error message to the web page using begin_rescue_end --- Joseph
	begin
		params[:import_data].each_value do |item|		
			item.each_key do |subitem|
				if subitem == 'case_data'
					item.each_value do |subitems|
						subitems.each_value do |sub|
							sub.each_value do |subs|
								ppm_id = subs[:PPMID]
								project_name = subs[:'E2E Project Name']
								test_case_name = subs[:'E2E Test Case Name']
								test_case_type = subs[:'Execution Type']
								exec_type = subs[:'Test Case Type']
								owner = subs[:Owner]
								# hyperlink = subs[:'Reference Link']
								hyperlink = ''

								# Flow Vars
								seq_id = subs[:'Application Index']
								appname = subs[:'Application Name']
								# portfolio = subs[:'Portfolio']
								portfolio = ''
								env_box = subs[:'Environment Box']
								# biz_proc = subs[:'Biz Process/T-Code']
								biz_proc = subs[:'Data Input/T-Code']
								key_doc = subs[:'Key Document Type']
								com_code = subs[:'Company Codes']
								solo_case_nameO = subs[:'Solo Test Cases']
								# portfolio = portfolio.gsub("\n", "<br>") if portfolio != nil
								# env_box = env_box.gsub("\n", "<br>") if env_box != nil
								# biz_proc = biz_proc.gsub("\n", "<br>") if biz_proc != nil
								# key_doc = key_doc.gsub("\n", "<br>") if key_doc != nil
								# com_code = com_code.gsub("\n", "<br>") if com_code != nil

								# Check this isn't the header; if it's a data row create
								if ppm_id != 'PPMID'
									if ppm_id != nil

										# Detect if we are doing an update or create for Test Case header  
										appHandler = AppHandler.new
										updateHeader_id = appHandler.detectUpdateCase(item, cur_row)

										# Create / Map Flow
										appHandler = AppHandler.new
										appHandler.mapcreateFlow(mapflowList, flowList, h_id, newName) if (h_id != 0) 

										# Clear the arrays
										mapflowList = Array.new
										flowList = Array.new	
										arrCombo = Array.new
										newName = ""										

										if updateHeader_id == nil
											header_id = TestCaseHeader.create(
														:flow_id =>1,				# TEMP DATA
														:temp_flow=>true,
														:test_case_name =>test_case_name,
														:project =>project_name,
														:ppm_id =>ppm_id,
														# :portfolio =>portfolio,
														:exec_type =>exec_type,
														:test_case_type =>test_case_type,
														:hyperlink =>hyperlink,
														:owner =>owner,
														:last_modified_time => Time.now
											 		)
											h_id = header_id[:id]
											casesImported = casesImported + 1	
											caseList.push(Hash["id", h_id, "name", test_case_name, "type", "create"])									
										else
											# Update Test Case header
											puts '!!!!!!!!!!!!!!!!!!!!!!!!UPDATE IMPORT HEADER!!!!!!!!!!!!!!!!!!!!!!!!!!'	
											h_id = 0
											test = TestCaseHeader.first_or_create(:id=>updateHeader_id)
											test.update(:test_case_name =>test_case_name,:project =>project_name,:ppm_id =>ppm_id,:exec_type =>exec_type,:test_case_type =>test_case_type,:hyperlink =>hyperlink,:owner =>owner)											
											# casesImported = casesImported + 1
											casesUpdated = casesUpdated + 1
											caseList.push(Hash["id", updateHeader_id, "name", test_case_name, "type", "update"])	
										end
									end

									# Get app info or create it if needed
									pro_id = appname.split(' - ').first
									app = appname.gsub(pro_id + ' - ', '')
									curapp = App.first(:project_id => pro_id)

									# if curapp == nil
									# 	curapp = App.create(:app_name => app,:project_id =>pro_id,:create_by =>'IMPORT',:create_at => Time.now)	
									# end
									appid = curapp[:id]

									# Save the apps and sequence to check flow mapping and creation later
									mapflowList.push(seq_id + ',' + appid.to_s)
									flowList.push(appid)
									arrCombo = appname.split(' - ')
									newName += arrCombo[1] + ' > '

									if updateHeader_id == nil
										# Create the Test Case Detail for this row of data
										newtcd = TestCaseDetail.create(:project_id =>appname,:environment_box =>env_box,:business_process=>biz_proc,:covered_type=>key_doc,:company_code=>com_code,:portfolio=>portfolio,:sequence_id=>seq_id,:app_id=>appid,:solo_case_header_id=>1,:test_case_header_id=>h_id)
										newtcd_id = newtcd[:id]
										tcdList.push([newtcd_id, solo_case_nameO])		
									else
										#  Update Test Case Details
										puts '!!!!!!!!!!!!!!!!!!!!!!!!UPDATE IMPORT DETAILS!!!!!!!!!!!!!!!!!!!!!!!!!!'									
										test = TestCaseDetail.first_or_create(:test_case_header_id=>updateHeader_id, :sequence_id => seq_id)

										# Get and use the current solocase id on update [ASSUMES THAT NOTHING HAS CHANGED!]
										sc_id = test[:solo_case_header_id]

										test.update(:project_id =>appname,:environment_box =>env_box,:business_process=>biz_proc,:covered_type=>key_doc,:company_code=>com_code,:portfolio=>portfolio,:sequence_id=>seq_id,:app_id=>appid,:solo_case_header_id=>sc_id)	
										
										# Make a list of updated records
										tcdList.push([test[:id].to_i, solo_case_nameO])
									end
								end
								cur_row = cur_row + 1
							end
						end
					end
				end

				if subitem == 'step_data'
					idx = 0
					item.each_value do |subitems|
						subitems.each_value do |sub|
							sub.each_value do |subs|	
								# test_case_name = subs[:'E2E Test Case Name']		
								# seq_id = subs[:'Application Index']
								appname = subs[:'Application Name']
								# solo_case_name = subs[:'Solo Test Case Name']
								solo_case_name = subs[:'Solo Test Cases Name']

								# step_id = subs[:'Step Index']
								step_id = subs[:'Step Name']
								# proc_name = subs[:'Process Name']
								proc_name = ''
								step_desc = subs[:'Description']
								expec_result = subs[:'Expected Result']
								# data_input = subs[:'Data Input']
								data_input = ''

								# proc_name = proc_name.gsub("\n", "<br>") if proc_name != nil
								# step_desc = step_desc.gsub("\n", "<br>") if step_desc != nil
								# expec_result = expec_result.gsub("\n", "<br>") if expec_result != nil
								# data_input = data_input.gsub("\n", "<br>") if data_input != nil

								# Check this isn't the header; if it's a data row create
								if step_id != 'Step Name'
									# Solo Case Header
									if solo_case_name != nil and step_id.to_i == 1

										appHandler = AppHandler.new
										updateHeader_id = appHandler.detectUpdateHeader(solo_case_name, appname)	

										if updateHeader_id == nil
											puts '!!!!!!!!!!!!!!Create New Solo Case!!!!!!!!!!!!!!!!'

											#  Find the app id by app name
											pro_id = appname.split(' - ').first
											app = appname.gsub(pro_id + ' - ', '')
											curapp = App.first(:project_id => pro_id)
											appid = curapp[:id]

											#  Create the solo case header
											soloHead = SoloCaseHeader.create(:solo_case_name=>solo_case_name,:app_id=>appid)	
											updateHeader_id = soloHead[:id]

											#  Update Test Case Details
											# tcd_id = tcdList[idx]
											# tcd = TestCaseDetail.first_or_create(:id => tcd_id)
											# tcd.update(:solo_case_header_id => solo_h_id)
											# idx = idx + 1								
										end
									end	

									# puts '&*&*&*&*&*&*&*&*&*&*&*&*&*&*&*&*&*&*&&*&&*&*&*&*'
									# puts step_desc
									# puts '&*&*&*&*&*&*&*&*&*&*&*&*&*&*&*&*&*&*&&*&&*&*&*&*'

									# Check if the step exists for the given solo_case
									appHandler = AppHandler.new
									updateStep_id = appHandler.detectUpdateStep(updateHeader_id, step_id)
									
									#  Solo Case Steps
									if updateStep_id == nil
										puts '!!!!!!!!!!!!!!Create New Solo Case Step!!!!!!!!!!!!!'
										SoloCaseStep.create(:step_id => step_id, :step_description => step_desc, :expected_result => expec_result, :process_name => proc_name, :data_input => data_input, :solo_case_header_id => updateHeader_id)									
									else
										puts '!!!!!!!!!!!!!!Update Solo Case Step!!!!!!!!!!!!!'
										step = SoloCaseStep.first(:solo_case_header_id => updateHeader_id, :step_id => step_id)
										step.update(:step_id=>step_id,:step_description=>step_desc,:expected_result=>expec_result,:process_name=>proc_name,:data_input=>data_input)	
									end
								end
								curStep_row = curStep_row + 1
							end
						end
					end				
				end
			end

			# Create / Map the last Flow 
			if updateHeader_id == nil
				puts '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!Create / Map Last Flow!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
				appHandler = AppHandler.new
				appHandler.mapcreateFlow(mapflowList, flowList, h_id, newName) if (h_id != 0) 		
			end

			# Clear the arrays
			# mapflowList = Array.new
			# flowList = Array.new	
			# arrCombo = Array.new
			# tcdList = Array.new
			# newName = ""										
		end

		# Link TCD records that were created or updated to their correct solo case headers
		# puts '(((((((((((((((((((((((((((((((((((((('
		for i in 0..tcdList.length - 1
		    # puts tcdList[i][0]
		    # puts tcdList[i][1]

		    # get the tcd records by id
			curdetail= TestCaseDetail.first(:id => tcdList[i][0])

			soloHead = SoloCaseHeader.first(:solo_case_name => tcdList[i][1], :app_id => curdetail[:app_id])
			solo_h_id = soloHead[:id]

			#  Update Test Case Detail
			curdetail.update(:solo_case_header_id => solo_h_id)
		end
		# puts '))))))))))))))))))))))))))))))))))))))'

		# puts '<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<'
		# @result.each { |item| 
		# 	conv_result.push(Hash[item.each_pair.to_a])
		# }
		# casesDone = Hash["created" => casesImported, "updated" => casesUpdated]
		# puts caseList.inspect
		# puts '<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<'
		caseList = caseList.flatten.uniq

		return caseList.to_json

	rescue =>error
		status 500
		error_1="Ruby Error #{error.class}"+"Ruby Error #{$!} Ruby Error#{$@}"
	end
end

get "/searchFlowTC/:flow&:tc" do
	found = false

	flow_conditions = params[:flow]
	p = CGI.parse(flow_conditions)
	apps = p['flow'].first
	apps = apps.split('|')

	# Add sequence to the App IDs
	cnt = 1
	apps.each { |app|
		apps[cnt - 1] = cnt.to_s + ',' + app
		cnt = cnt + 1
	}

	tc_conditions = params[:tc]
	p = CGI.parse(tc_conditions)
	#flow_conditions = flow_conditions.split("|")
	tcName = p['tc'].first

	appHandler = AppHandler.new
	mappedFlow = appHandler.mapFlow(apps)

	if mappedFlow != 0
		# Check for a test case with the flow and name
		tcs = TestCaseHeader.count(:test_case_name => tcName, :flow_id => mappedFlow)
		# puts '@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#'
		# puts tcs
		# puts '@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#'

		if tcs > 0 
			found = true
		end
	end

	# puts '@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#'
	# puts apps.inspect
	# puts tcName
	# puts '@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#'

	return found.to_json
end

get "/searchSoloName/:soloList" do
	found = ""

	# Extract parameter lists
	solo_conditions = params[:soloList]
	p = CGI.parse(solo_conditions)
	soloList = p['soloList'].first
	soloList.gsub! '¶', ','
	soloList = soloList.split('|')

	# Check each solo case to see if it exists for an app
	soloList.each { |name|
		arrCombo = name.split(',')
		caseName = arrCombo[0]
		app_id = arrCombo[1]

		scs = SoloCaseHeader.count(:solo_case_name => caseName, :app_id => app_id)
		if scs != 0
			app = App.first(:id => app_id)
			appName = app[:app_name]
			msg = "Product: " + appName + "; Case Name: " + caseName
			return msg.to_json
		end
	}

	return found.to_json
end

get '/topflows/:type' do
	conditions = params[:type]
	p = CGI.parse(conditions)
	type = p['type'].first

	# puts '***************'
	# puts type
	# puts '***************'

	# Top 10 flows by associated project count / case count
	adapter = DataMapper.repository(:default).adapter
	sql = 'SELECT flow_des, COUNT(flow_des) FROM (SELECT DISTINCT flow_des, ppm_id FROM `flows` INNER JOIN test_case_headers ON test_case_headers.flow_id = flows.id WHERE temp_flow = 0 ORDER BY flow_des) A GROUP BY A.flow_des ORDER BY COUNT(A.flow_des) DESC'

	# Run the SQL statement
	results = adapter.select(sql)	
	results = results.flatten.uniq		

	# Count up the results from the sql data
	countResults = []
	results.each { |item| 
		# Find the number of related cases
		sqlCaseCnt = "SELECT DISTINCT flow_id, flow_des, test_case_headers.id, test_case_name FROM `flows` INNER JOIN test_case_headers ON test_case_headers.flow_id = flows.id WHERE temp_flow = 0 AND flow_des = '" + item['flow_des'] + "'" 
		resultCnt = adapter.select(sqlCaseCnt)	
		resultCnt = resultCnt.flatten.uniq	
		firstItem = resultCnt[0]
		flowid = firstItem['flow_id']
		
		sqlProjList = "SELECT ppm_id, COUNT(ppm_id) FROM (SELECT flow_des, ppm_id FROM `flows` INNER JOIN test_case_headers ON test_case_headers.flow_id = flows.id WHERE temp_flow = 0 AND flow_des = '" + item['flow_des'] + "' ORDER BY flow_des) A GROUP BY A.ppm_id ORDER BY COUNT(A.ppm_id) DESC"
		resultProj = adapter.select(sqlProjList)
		resultProj = resultProj.flatten.uniq

		projectList = []
		resultProj.each { |item| 
			# device = app_name; count = #related ppm_id; label = app#; caseCnt = #related e2e cases
			projectList.push([item['ppm_id'], item['count(ppm_id)']])
		}	

		# device = app_name; count = #related ppm_id; label = app#; caseCnt = #related e2e cases
		# if type == 'cases'
		# 	countResults.push(Hash["device", item['flow_des'], "count", resultCnt.length, "label", "", "caseCnt", item['count(flow_des)'], "flow_id", flowid]) 				
		# else
			countResults.push(Hash["device", item['flow_des'], "count", item['count(flow_des)'], "label", "", "caseCnt", resultCnt.length, "flow_id", flowid, "proj_list", projectList])
		# end
	}

	# Sort the list
	if type == 'cases'
		countResults.sort! { |countResults, b| [countResults["caseCnt"], countResults["count"]] <=> [b["caseCnt"], b["count"]]}
	else
		countResults.sort! { |countResults, b| [countResults["count"], countResults["caseCnt"]] <=> [b["count"], b["caseCnt"]]}
	end
	countResults = countResults.reverse
	# countResults = countResults[0,10]

	# Put the proper label in after sorting 
	cnt = 1
	countResults.each { |item| 
		item["label"] = "#" + cnt.to_s + " Flow"
		cnt += 1
	}

	return countResults.to_json
end

get '/topapps/:type' do
	conditions = params[:type]
	p = CGI.parse(conditions)
	type = p['type'].first

	# Top 10 apps by associated project count / case count
	adapter = DataMapper.repository(:default).adapter
	sql = 'SELECT app_name, app_id, COUNT(app_id) FROM (SELECT DISTINCT app_id, app_name, test_case_header_id FROM test_case_details INNER JOIN test_case_headers ON test_case_headers.id = test_case_details.test_case_header_id INNER JOIN apps ON apps.id = test_case_details.app_id ORDER BY app_name) A GROUP BY A.app_id ORDER BY COUNT(app_id) DESC'

	# Run the SQL statement
	results = adapter.select(sql)	
	results = results.flatten.uniq		

	# Count up the results from the sql data
	countResults = []
	results.each { |item| 
		# Find the number of related cases
		sqlCaseCnt = "SELECT DISTINCT app_id, ppm_id FROM test_case_headers INNER JOIN test_case_details ON test_case_details.test_case_header_id = test_case_headers.id WHERE app_id = " + item['app_id'].to_s 
		resultCnt = adapter.select(sqlCaseCnt)	
		resultCnt = resultCnt.flatten.uniq	
		firstItem = resultCnt[0]
		appid = firstItem['app_id']

		sqlProjList = "SELECT ppm_id, COUNT(ppm_id) FROM (SELECT DISTINCT test_case_headers.id, ppm_id FROM test_case_headers INNER JOIN test_case_details ON test_case_details.test_case_header_id = test_case_headers.id WHERE app_id = " + appid.to_s + ") A GROUP BY A.ppm_id ORDER BY COUNT(A.ppm_id) DESC"
		resultProj = adapter.select(sqlProjList)
		resultProj = resultProj.flatten.uniq

		projectList = []
		resultProj.each { |item| 
			# device = app_name; count = #related ppm_id; label = app#; caseCnt = #related e2e cases
			projectList.push([item['ppm_id'], item['count(ppm_id)']])
		}

		# device = app_name; count = #related ppm_id; label = app#; caseCnt = #related e2e cases
		# if type == 'cases'
		# 	countResults.push(Hash["device", item['app_name'], "count", item['count(app_id)'], "label", "", "caseCnt", resultCnt.length]) 				
		# else
			countResults.push(Hash["device", item['app_name'], "count", resultCnt.length, "label", "", "caseCnt", item['count(app_id)'], "app_id", appid, "proj_list", projectList])
		# end
	}

	# Sort the list
	if type == 'cases'
		countResults.sort! { |countResults, b| [countResults["caseCnt"], countResults["count"]] <=> [b["caseCnt"], b["count"]]}
	else
		countResults.sort! { |countResults, b| [countResults["count"], countResults["caseCnt"]] <=> [b["count"], b["caseCnt"]]}
	end
	countResults = countResults.reverse
	# countResults = countResults[0,20]

	# Put the proper label in after sorting 
	cnt = 1
	countResults.each { |item| 
		item["label"] = "#" + cnt.to_s + " App"
		cnt += 1
	}

	return countResults.to_json
end

get '/dashboard_flows_proj' do
	@e2eCaseCount = TestCaseHeader.count()
	@soloCaseCount = SoloCaseHeader.count()
	@flowCount = Flow.count()
	@appCount = App.count()

	erb :dashboardFlowsProj
end

get '/dashboard_flows_case' do
	@e2eCaseCount = TestCaseHeader.count()
	@soloCaseCount = SoloCaseHeader.count()
	@flowCount = Flow.count()
	@appCount = App.count()

	erb :dashboardFlowsCase
end

get '/dashboard_apps_proj' do
	@e2eCaseCount = TestCaseHeader.count()
	@soloCaseCount = SoloCaseHeader.count()
	@flowCount = Flow.count()
	@appCount = App.count()

	erb :dashboardAppsProject
end

get '/dashboard_apps_case' do
	@e2eCaseCount = TestCaseHeader.count()
	@soloCaseCount = SoloCaseHeader.count()
	@flowCount = Flow.count()
	@appCount = App.count()

	erb :dashboardAppsCase
end

get '/get_project_list/:flow_id' do
	conditions = params[:flow_id]
	p = CGI.parse(conditions)
	flow_id = p['flow_id'].first

	# Get the flow_des for this flow_id
	flow = Flow.all(:id => flow_id.to_i)
	# puts flow.inspect
	flow_des = flow[0].flow_des

	adapter = DataMapper.repository(:default).adapter
	sql = "SELECT ppm_id, COUNT(ppm_id) FROM (SELECT flow_des, ppm_id FROM `flows` INNER JOIN test_case_headers ON test_case_headers.flow_id = flows.id WHERE temp_flow = 0 AND flow_des = '" + flow_des + "' ORDER BY flow_des) A GROUP BY A.ppm_id ORDER BY COUNT(A.ppm_id) DESC"

	# Run the SQL statement
	results = adapter.select(sql)	
	results = results.flatten.uniq	

	fixedResults = []
	results.each { |item| 
		# device = app_name; count = #related ppm_id; label = app#; caseCnt = #related e2e cases
		fixedResults.push(Hash["ppmid", item['ppm_id'], "count", item['count(ppm_id)']])
	}	

	return fixedResults.to_json
end

get '/get_appproj_list/:app_id' do
	conditions = params[:app_id]
	p = CGI.parse(conditions)
	app_id = p['app_id'].first

	adapter = DataMapper.repository(:default).adapter
	sql = "SELECT ppm_id, COUNT(ppm_id) FROM (SELECT DISTINCT test_case_headers.id, ppm_id FROM test_case_headers INNER JOIN test_case_details ON test_case_details.test_case_header_id = test_case_headers.id WHERE app_id = " + app_id + ") A GROUP BY A.ppm_id ORDER BY COUNT(A.ppm_id) DESC"

	# Run the SQL statement
	results = adapter.select(sql)	
	results = results.flatten.uniq	

	fixedResults = []
	results.each { |item| 
		# device = app_name; count = #related ppm_id; label = app#; caseCnt = #related e2e cases
		fixedResults.push(Hash["ppmid", item['ppm_id'], "count", item['count(ppm_id)']])
	}	

	return fixedResults.to_json
end