#encoding: utf-8
require "sinatra" 
require "sinatra/reloader" if development?
$LOAD_PATH.unshift(File.dirname(__FILE__))
require "model/models"
#Include to read the excel
require "parseexcel/parser"
require "win32ole"

# A Postgres connection:
#ENV['DATABASE_URL']
#ENV['HEROKU_POSTGRESQL_NAVY_URL']
#DataMapper.setup(:default, ENV['HEROKU_POSTGRESQL_NAVY_URL'] ||'postgres://postgres:postgres@localhost/postgres')

class AppHandler

	# load the excel
	def read_excel(excel)
		require 'pp'
		require 'Win32API'
		coInitialize = Win32API.new('ole32', 'CoInitialize', 'P', 'L')
		coInitialize.call 0
		workbook = WIN32OLE.new('excel.application').workbooks.open((Dir.pwd + excel).gsub('/', '\\'))
		worksheet = workbook.worksheets 1
		excelData = worksheet.usedrange.value
		excelData.shift
		# excelData.map {|a| a[0].to_i.to_s}
		m = Mysql.new("localhost","root","","e2e")
		excelData.each do |items|
			# puts items[1..-2]
			items[0] = items[0].to_i.to_s
			statement = "INSERT INTO apps (project_id,app_name,l2_owner,l3_owner,app_alias,create_by,create_at) VALUES ";
			statement = "#{statement}('"+items.join("','")+"',?)"
			st = m.prepare(statement)
			st.execute(Time.now)
		end
		return "Loaded data successfully! <a href='/main'>back to main page</a>"
	ensure
		workbook.close unless workbook.nil?
	end

	def viewAllModules()
		# modules = Flow.all(:limit =>5)
		modules = Flow.all(:order => [ :flow_name.asc ])

		# Hijack the description field for case count
		modules.each { |item| 
			item[:flow_des] = TestCaseHeader.count(:flow_id => item[:id])
		}

		#modules = FlowModule.all('flow.id'=>1)
		# modules = Flow.all().flowModules(:flow_id => Flow.id)
		# puts modules
		return modules
	end

	def login(username,password)
		user = Users.first(username: username)
		usr = user.username
		pwd = user.password
		if username == usr&&password==pwd
			return true
		else
			return false
		end
	end

	#删除one-to-many例子
	def deleteApp(appid)
		#删除中间表的数据
		app = App.get(appid.to_i).appFlowRels.destroy
		puts app
		#然后删除单条记录的数据
		puts App.get(appid.to_i).destroy
		return "Delete APP successfully!"
	end

	#更新one-to-many例子
	def updateApp(appid)
		app = App.get(appid.to_i).appFlowRels.update(flow_id: 2)
		puts app.inspect
	end

	def createApp(appname,projectid,appalias,l2owner,l3owner,createby)
		@app = App.create(
			:app_name =>appname,
			# :app_des =>appdes,
			:project_id =>projectid,
			:app_alias =>appalias,
			:l2_owner =>l2owner,
			:l3_owner =>l3owner,
			:create_by =>createby
			)
		# if @app.save
		# 	"Add APP successfully！"
		# else 
		# 	@app.errors
		# end
	end                                        

	#添加many-to-many的例子
	def createAppFlow(flowname,flowdes,appArr,createby)
		# flow = Flow.create(:flow_name =>"SM->CIS-CDS",:flow_des=>"This is a test",:create_at=>Time.now)
		# app1 = App.create(:project_id =>"10001", :app_name =>"CIS",:create_by=>"Tony",:create_at=>Time.now)
		# app2 = App.create(:project_id =>"10002", :app_name =>"SM",:create_by=>"Tony",:create_at=>Time.now)
		# app3 = App.create(:project_id =>"10003", :app_name =>"CDS",:create_by=>"Tony",:create_at=>Time.now)
		#puts app.inspect

		# flow = Flow.get(2)
		# link = AppFlow.get(flow.id)
		# link.destory!
		
		flow = Flow.create(:flow_name =>flowname,:flow_des=>flowdes,:create_by=>createby,:create_at=>Time.now)

		appArr.each do |key,value|
			app = App.get(value)
			puts "key is #{key}"
			# puts app.inspect
			AppFlowRel.create(:flow => flow,:app => app,:sequence_id=>key.to_i)
		end
		return flow[:id]
		# link = AppFlow.get(create)
		# flow.appFlowRels.destroy
		# flow.destroy

		# if app.destroy
		# 	puts 'OK'
		# 	else
		# 	puts 'Fail'
		# end
		#flow.apps <<app1 <<app2
		# flow.apps = [app1, app2, app3]
		# flow.save

		# AppFlow.create(:flow => flow,:app => app)
		# AppFlow.create(:flow => flow,:app => app2)
		# puts app.inspect
		# app.each do |item|
		# 	puts item.id
		# 	# link = AppFlow.get(item.id, flow.id)
		# 	# link.destroy
		# end
		# link = AppFlow.get(app.id, flow.id)
		# link.destroy
		# puts App.get(1).destroy
		# FlowApp.create(:app =>app1, :flow=>flow)

		# app = App.create(:project_id =>"10001", :app_name =>"SM",:create_by=>"Tony",:create_at=>Time.now)
		# app2 = App.create(:project_id =>"10002", :app_name =>"CIS",:create_by=>"Tony",:create_at=>Time.now)
		# app3 = App.create(:project_id =>"10003", :app_name =>"CDS",:create_by=>"Tony",:create_at=>Time.now)
		# flow = Flow.create(:flow_name =>"CDS->CIS->SM", :flow_des=>"CDS >CIS > SM workflow",:create_by=>"Larry",:create_at=>Time.now)
		# appflow = appFlowRels.create(:app =>app, :flow=>flow, :app_flow_des=>"This is a test")
		# appflow2 = appFlowRels.create(:app =>app2, :flow=>flow, :app_flow_des=>"This is a test")
		# appflow3 = appFlowRels.create(:app =>app3, :flow=>flow, :app_flow_des=>"This is a test")
		# app.appFlowRels
		# app2.appFlowRels
		# app3.appFlowRels
		# flow.flowrel
		# p = Person.create
		# t = Task.create(:person => p,:des => "123")
		# p.tasks
		# return "come here"
		# appflow = appFlowRels.create
		# app = Applist.create :appflowrel => appflow
		# appflow.applist
	end

	def view_spec_apps(conditions)
		if (conditions.empty?)
			put "condition is empty"
		end
		apps = []
		conditions.each do |condition|
			puts condition.to_i
			# 判断字符是否是数字
			if condition.numeric?
				puts "是数字"
				apps << App.all(:project_id.like=>"%#{condition}%", :limit => 12)
			else
				puts "不是数字"
				apps << App.all(:app_name.like=>"%#{condition}%", :limit => 12)
			end
		end
		# apps = App.all(:app_name.like=>"%SMB%")|App.all(:app_name.like=>"%Omega%")
		apps = apps.flatten
		apps = apps.uniq
	end

	def view_spec_flows_by_FlowName(conditions)
		flows = []


		conditions.each do |condition|
			condition = condition.strip()
			flows << Flow.all(:flow_name.like=>"%#{condition}%")
		end			

		flows = flows.flatten
		flows = flows.uniq
	end

	def view_spec_flows_by_AppName(conditions)
		apps = []
		flowRels = []
		flows = []

		conditions.each do |condition|
			condition = condition.strip()
			apps << App.all(:app_name.like=>"%#{condition}%")
			apps << App.all(:project_id.like=>"%#{condition}%")
			apps = apps.flatten
			apps = apps.uniq

			apps.each do |app_condition|
				# puts '@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@'
				# puts flow_condition.id
				# puts '@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@'
				flowRels = AppFlowRel.all(:app_id=>app_condition.id)
				flowRels.each do |flow_condition|
					flows << Flow.all(:id=>flow_condition.flow_id)
				end
			end			
		end

		flows = flows.flatten
		flows = flows.uniq
		# puts '@@@@@@@@@@@@@@@@@AppName Search@@@@@@@@@@@@@@@@@@@@'
		# puts flows.inspect
		# puts '@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@'	
	end

	def view_spec_flows_by_ComCode(conditions)
		tcs = []
		flows = []
		tc = []

		conditions.each do |condition|
			condition = condition.strip()
			tcs = TestCaseDetail.all(:company_code.like=>"%#{condition}%")
			tcs.each do |tcs_condition|
				# puts '@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@'
				# puts flow_condition.id
				# puts '@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@'
				tc = TestCaseHeader.all(:id=>tcs_condition.test_case_header_id)
				tc.each do |tc_condition|
					flows << Flow.all(:id=>tc_condition.flow_id)
				end
			end			
		end

		flows = flows.flatten
		flows = flows.uniq
		# puts '@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@'
		# puts flows.inspect
		# puts '@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@'	
	end

	def view_spec_flows_by_Portfolio(conditions)
		tcs = []
		flows = []
		tc = []

		conditions.each do |condition|
			condition = condition.strip()
			tcs = TestCaseDetail.all(:portfolio.like=>"%#{condition}%")
			tcs.each do |tcs_condition|
				# puts '@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@'
				# puts flow_condition.id
				# puts '@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@'
				tc = TestCaseHeader.all(:id=>tcs_condition.test_case_header_id)
				tc.each do |tc_condition|
					flows << Flow.all(:id=>tc_condition.flow_id)
				end
			end			
		end

		flows = flows.flatten
		flows = flows.uniq
	end

	def view_spec_flows_by_PPMID(conditions)
		tcs = []
		flows = []

		conditions.each do |condition|
			condition = condition.strip()
			tcs = TestCaseHeader.all(:ppm_id.like=>"%#{condition}%")
			tcs.each do |tc_condition|
				# puts '@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@'
				# puts flow_condition.id
				# puts '@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@'
				flows << Flow.all(:id=>tc_condition.flow_id)
			end			
		end

		flows = flows.flatten
		flows = flows.uniq
		# puts '@@@@@@@@@@@@@@@@@view_spec_flows_by_PPMID@@@@@@@@@@@@@@@@@@'
		# puts flows.inspect
		# puts '@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@'
	end

	def view_spec_flows_by_EnvBox(conditions)
		tcs = []
		flows = []
		tc = []

		conditions.each do |condition|
			condition = condition.strip()
			tcs = TestCaseDetail.all(:environment_box.like=>"%#{condition}%")
			tcs.each do |tcs_condition|
				tc = TestCaseHeader.all(:id=>tcs_condition.test_case_header_id)
				tc.each do |tc_condition|
					flows << Flow.all(:id=>tc_condition.flow_id)
				end
			end			
		end

		flows = flows.flatten
		flows = flows.uniq
	end

	def view_spec_flows_by_KeyDoc(conditions)
		tcs = []
		flows = []
		tc = []

		conditions.each do |condition|
			condition = condition.strip()
			tcs = TestCaseDetail.all(:covered_type.like=>"%#{condition}%")
			tcs.each do |tcs_condition|
				# puts '@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@'
				# puts flow_condition.id
				# puts '@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@'
				tc = TestCaseHeader.all(:id=>tcs_condition.test_case_header_id)
				tc.each do |tc_condition|
					flows << Flow.all(:id=>tc_condition.flow_id)
				end
			end			
		end

		flows = flows.flatten
		flows = flows.uniq
	end

	def view_spec_flows_by_BizProc(conditions)
		tcs = []
		flows = []
		tc = []

		conditions.each do |condition|
			condition = condition.strip()
			tcs = TestCaseDetail.all(:business_process.like=>"%#{condition}%")
			tcs.each do |tcs_condition|
				# puts '@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@'
				# puts flow_condition.id
				# puts '@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@'
				tc = TestCaseHeader.all(:id=>tcs_condition.test_case_header_id)
				tc.each do |tc_condition|
					flows << Flow.all(:id=>tc_condition.flow_id)
				end
			end			
		end

		flows = flows.flatten
		flows = flows.uniq
	end

	def view_spec_flows_by_E2ECase(conditions)
		tcs = []
		flows = []

		conditions.each do |condition|
			condition = condition.strip()
			tcs = TestCaseHeader.all(:test_case_name.like=>"%#{condition}%")
			tcs.each do |tc_condition|
				# puts '@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@'
				# puts flow_condition.id
				# puts '@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@'
				flows << Flow.all(:id=>tc_condition.flow_id)
			end			
		end

		flows = flows.flatten
		flows = flows.uniq		
	end	

	def view_spec_tc(id_conditions, coCode_conditions, ppmId_conditions, portf_conditions, envbox_conditions, keyDoc_conditions, bizProc_conditions, e2eCase_conditions)
		tc = []
		tc_ComCode = []
		tc_PPMID = []
		tc_Portfolio = []
		tc_TempFlow = []
		tc_EnvBox = []
		tc_KeyDoc = []
		tc_BizProc = []
		tc_E2EName = []

		# Get a list of Test Cases without Flows
		tc_TempFlow = TestCaseHeader.all(:temp_flow=>true)
		tc_TempFlow = tc_TempFlow.flatten
		tc_TempFlow = tc_TempFlow.uniq
		# puts '()()()()()()()()()()()()()()()()()()()()'
		# puts tc_TempFlow.inspect
		# puts '()()()()()()()()()()()()()()()()()()()()'

		result = []
		result = TestCaseHeader.all() 
		result = result.flatten.uniq

		# Company Code Search Field
		if coCode_conditions.length != 0
			coCode_conditions.each do |code_condition|
				code_condition = code_condition.strip()
				tcs = TestCaseDetail.all(:company_code.like=>"%#{code_condition}%")
				tcs.each do |tcs_condition|
					tc_ComCode << TestCaseHeader.all(:id=>tcs_condition.test_case_header_id)
				end			
			end
			tc_ComCode = tc_ComCode.flatten
			tc_ComCode = tc_ComCode.uniq
			result = result & tc_ComCode
		end

		# Portfolio Search Field
		if portf_conditions.length != 0
			portf_conditions.each do |code_condition|
				code_condition = code_condition.strip()
				tcs = TestCaseDetail.all(:portfolio.like=>"%#{code_condition}%")
				tcs.each do |tcs_condition|
					tc_Portfolio << TestCaseHeader.all(:id=>tcs_condition.test_case_header_id)
				end			
			end
			tc_Portfolio = tc_Portfolio.flatten
			tc_Portfolio = tc_Portfolio.uniq
			result = result & tc_Portfolio			
		end

		# Environment Box Search Field
		if envbox_conditions.length != 0
			envbox_conditions.each do |code_condition|
				code_condition = code_condition.strip()
				tcs = TestCaseDetail.all(:environment_box.like=>"%#{code_condition}%")
				tcs.each do |tcs_condition|
					tc_EnvBox << TestCaseHeader.all(:id=>tcs_condition.test_case_header_id)
				end			
			end
			tc_EnvBox = tc_EnvBox.flatten
			tc_EnvBox = tc_EnvBox.uniq	
			result = result & tc_EnvBox			
		end

		# Key Doc Search Field
		if keyDoc_conditions.length != 0
			keyDoc_conditions.each do |code_condition|
				code_condition = code_condition.strip()
				tcs = TestCaseDetail.all(:covered_type.like=>"%#{code_condition}%")
				tcs.each do |tcs_condition|
					tc_KeyDoc << TestCaseHeader.all(:id=>tcs_condition.test_case_header_id)
				end			
			end
			tc_KeyDoc = tc_KeyDoc.flatten
			tc_KeyDoc = tc_KeyDoc.uniq	
			result = result & tc_KeyDoc	
		end

		# Biz Process Search Field
		if bizProc_conditions.length != 0
			bizProc_conditions.each do |code_condition|
				code_condition = code_condition.strip()
				tcs = TestCaseDetail.all(:business_process.like=>"%#{code_condition}%")
				tcs.each do |tcs_condition|
					tc_BizProc << TestCaseHeader.all(:id=>tcs_condition.test_case_header_id)
				end			
			end
			tc_BizProc = tc_BizProc.flatten
			tc_BizProc = tc_BizProc.uniq	
			result = result & tc_BizProc	
		end

		# PPM ID Search Field
		if ppmId_conditions.length != 0
			ppmId_conditions.each do |code_condition|
				code_condition = code_condition.strip()
				tc_PPMID << TestCaseHeader.all(:ppm_id.like=>"%#{code_condition}%")		
			end
			tc_PPMID = tc_PPMID.flatten
			tc_PPMID = tc_PPMID.uniq
			result = result & tc_PPMID
		end

		# E2E Case Name Search Field
		if e2eCase_conditions.length != 0
			e2eCase_conditions.each do |code_condition|
				code_condition = code_condition.strip()
				tc_E2EName << TestCaseHeader.all(:test_case_name.like=>"%#{code_condition}%")		
			end
			tc_E2EName = tc_E2EName.flatten
			tc_E2EName = tc_E2EName.uniq
			result = result & tc_E2EName
		end

		# Search by id
		id_conditions.each do |condition|
			condition = condition.strip()
			tc << TestCaseHeader.all(:flow_id=>condition)
		end

		# puts '%%%%%%%%%%%%%%%%%CUR DEBUG%%%%%%%%%%%%%%%%%%'
		# puts result.inspect
		# puts '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%'

		tc = tc.flatten
		tc = tc.uniq
		tc = tc & result
		tc = tc - tc_TempFlow
	end

	def view_orphan_tc(ppmId_conditions, e2eCase_conditions)
		# Get a list of orphan cases [w/o a flow] and filter it
		tc_PPMID = []
		tc_TempFlow = []
		tc_E2EName = []

		# Get a list of Test Cases without Flows
		tc_TempFlow = TestCaseHeader.all(:temp_flow=>true)
		tc_TempFlow = tc_TempFlow.flatten
		tc_TempFlow = tc_TempFlow.uniq
		# puts '()()()()()()()()()()()()()()()()()()()()'
		# puts tc_TempFlow.inspect
		# puts '()()()()()()()()()()()()()()()()()()()()'		

		# PPM ID Search Field
		if ppmId_conditions.length == 0
			tc_PPMID << TestCaseHeader.all()
		else
			ppmId_conditions.each do |code_condition|
				code_condition = code_condition.strip()
				tc_PPMID << TestCaseHeader.all(:ppm_id.like=>"%#{code_condition}%")		
			end

		end
		tc_PPMID = tc_PPMID.flatten
		tc_PPMID = tc_PPMID.uniq

		# E2E Case Name Search Field
		if e2eCase_conditions.length == 0
			tc_E2EName << TestCaseHeader.all()
		else
			e2eCase_conditions.each do |code_condition|
				code_condition = code_condition.strip()
				tc_E2EName << TestCaseHeader.all(:test_case_name.like=>"%#{code_condition}%")		
			end

		end
		tc_E2EName = tc_E2EName.flatten
		tc_E2EName = tc_E2EName.uniq


		tc_TempFlow = tc_TempFlow.flatten.uniq
		tc_TempFlow = tc_TempFlow & tc_PPMID & tc_E2EName
	end	


	def viewApp(count)
		apps = App.all(:limit => count)
		return apps
	end

	def viewFlow()
		count = Flow.count()

		flows = Flow.all( :order => [ :id.desc ])
		#flow = FlowModule.all(:flows =>)
	end

	def search_condition(conditions)
		apps = []
		# puts conditions.inspect
		conditions.each do |condition|
			# 判断字符是否是数字
			if condition.to_i.to_s==condition
				puts "是数字"
				apps << App.all(:project_id.like=>"%#{condition}%")
			else
				puts "不是数字"
				apps << App.all(:app_name.like=>"%#{condition}%")
			end
		end
		# apps = App.all(:app_name.like=>"%SMB%")|App.all(:app_name.like=>"%Omega%")
		apps = apps.flatten
		apps = apps.uniq
		puts apps.inspect
		# apps.each do |item|
		# 	#flow = Flow.all(:appFlowRels =>{:app_id=>item.flows})
		# 	item.flows
		# end
		
		# app.each do |item|
		# 	puts item.id
		# end
		flows = []
		apps.each do |app|
			flows << Flow.all(:appFlowRels =>{:app_id => app.id})
		end
		# 把二维数组变换成一维数组
		return flows.flatten.uniq
	end

	#显示包含app关建字的所有的workflow
	def searchSpecificFlow(appname)
		apps = App.all(:app_name => appname)
		apps = apps.flatten
		# puts apps.inspect
		# apps.each do |item|
		# 	#flow = Flow.all(:appFlowRels =>{:app_id=>item.flows})
		# 	item.flows
		# end
		
		# app.each do |item|
		# 	puts item.id
		# end

		flows = []
		flowRels = []
		apps.each do |app|
			# flows << Flow.all()
			flowRels = AppFlowRel.all(:app_id => app.id)
			flowRels = flowRels.uniq
			# puts flowRels.inspect

			flowRels.each do |flow_condition|
				flows << Flow.all(:id => flow_condition.flow_id)
			end

			# flows << Flow.all(:appFlowRels =>{:app_id => app.id})
		end
		if apps.length == 0
			flows = Flow.all()
		end

		# Hijack the description field for case count
		# flows = flows.flatten.uniq
		# flows.each { |item| 
		# 	item[:flow_des] = TestCaseHeader.count(:flow_id => item[:id])
		# }

		# puts flows.inspect
		return flows.flatten.uniq
	end

	def viewFlowApp(flowid)
		flow = App.all(:appFlowRels=>{:flow_id=>flowid})
		return flow
	end

	def viewFlowModule(flowid)
		modules = FlowModule.all(:flow_id =>flowid)
		puts modules
		return modules
	end

	def createModule(moduleArr)
		f = Flow.get(moduleArr["flowid"].to_i)
		if f 
		flow_module = f.flow_modules.new(:module_name =>moduleArr["modulename"],:module_des=>moduleArr["moduledes"],
			:exe_type=>moduleArr["moduletype"],:create_by=>moduleArr["createby"],:create_at=>Time.now)
		else
			return "Please to create flow first! <a href='/createflow'>back to main page</a>"
		end

		if f.save&&flow_module.save
			return "create module successfully! <a href='/demo'>back to main page</a>"
		else
			return "create module fail! <a href='/demo'>back to main page</a>"
		end

	end

	#创建one-to-many的例子
	def mannualAddModule(id)
		#f = Flow.create(:flow_name =>"CDS->CIS->SM", :flow_des=>"CDS >CIS > SM workflow test",:create_by=>"Larry",:create_at=>Time.now)
		#flow_module = FlowModule.create(:flow => f,:module_name =>"Automation",:module_des=>"this is automation scripts")
		#f.flowModules

		f = Flow.get(id.to_i)

		if f 
		flow_module = f.flow_modules.new(:module_name =>"Automation",:module_des=>"this is automation scripts",
			:exe_type=>"Auto",:create_by=>"Larry",:create_at=>Time.now)
		else
			return "Please to create flow first!!!"
		end

		if f.save&&flow_module.save
			return "create module successfully"
		else
			return "create module failure"
		end
	end

	# 		:name =>username,
	# 		:password =>password,
	# 		:created_at => Time.now
	# 		)
	# 	if @user.save
	# 		"你的用户名创建成功。请牢记你的用户名和密码<a href = /userlist>查看所有用户</a>"
	# 	else
	# 		@user.errors
	# 	end
	# end

	# def retrieveusers()
	# 	@userlist = Users.all(:id.gte =>1, :id.lte =>29)
	# 	return @userlist
	# end

	# def createTestCase(flow_id,test_case_name,project_name,ppm_id,portfolio,exec_type,test_case_type,hyperlink,owner)
	# 	@tc = TestCaseHeader.create(
	# 		:flow_id =>flow_id,
	# 		:test_case_name =>test_case_name,
	# 		:project_name =>project_name,
	# 		:ppm_id =>ppm_id,
	# 		:portfolio =>portfolio,
	# 		:exec_type =>exec_type,
	# 		:test_case_type =>test_case_type,
	# 		:hyperlink =>hyperlink,
	# 		:owner =>owner,
	# 		:last_modified_time => Time.now
	# 		)
	# 	if @tc.save
	# 		"Add Test Case successfully！"
	# 	else 
	# 		@tc.errors
	# 	end
	# end

	# def createStep(step_id,step_desc,expec_res,memo,tc_id)
	# 	@st = TestCaseStep.create(
	# 		:step_id =>step_id,
	# 		:step_description =>step_desc,
	# 		:expected_result =>expec_res,
	# 		:memo =>memo,
	# 		:test_case_header_id => tc_id
	# 		)
	# 	if @st.save
	# 		"Add Test Case successfully！"
	# 	else 
	# 		@st.errors
	# 	end
	# end

	def viewTestcaseHeader(tc_id)
		testcaseheaders = TestCaseHeader.all(:id =>tc_id)
		return testcaseheaders
	end

	def viewTestcaseHeaderAll()
		testcaseheaders = TestCaseHeader.all()
		return testcaseheaders
	end

	def viewTestcaseDetails(tc_id)
		testcasedetails = TestCaseDetail.all(:test_case_header_id =>tc_id)
		return testcasedetails
	end

	def viewTestcaseSteps(tc_id)
		testcasesteps = TestCaseStep.all(:test_case_header_id =>tc_id)
		return testcasesteps
	end

	def mapFlow(arrFlowList)
		app = ""
		seq = ""
		flows = []
		flowsFinal = []
		flowIDs = []

		# Find the flows that match these sequences
		firstSeq = true
		arrFlowList.each { |item|
			arrCombo = item.split(',')
			app = arrCombo[1]
			seq = arrCombo[0]

			#flows << AppFlowRel.all(:sequence_id =>seq, :app_id => app )

			flows = AppFlowRel.all(:sequence_id =>seq, :app_id => app )

			arrTemp = Array.new
			flows.each { |item| 
				temp = item[:flow_id]
				arrTemp.push(temp) 
			}

			if firstSeq == true
				# First time only

				# puts 'TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT'
				# puts flowsFinal.inspect
				# puts arrTemp.inspect
				# puts 'TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT'


				firstSeq = false
				flowsFinal = arrTemp
			else

				# puts '????????????????????????????????????????????'
				# puts flowsFinal.inspect
				# puts arrTemp.inspect
				# puts '????????????????????????????????????????????'


				flowsFinal = flowsFinal & arrTemp
			end

			# puts '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
			# puts flowsFinal.inspect
			# puts '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
		}

		# Remove Duplicates
		flowsFinal = flowsFinal.flatten.uniq
		# puts '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
		# puts flowsFinal.inspect
		# puts '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'

		flowsFinal.each { |item|
			flowParts = AppFlowRel.all(:flow_id => item)

			# Check the length of the flow is what we want
			if flowParts.length == arrFlowList.length
				# Return the Mapped ID
				return item
			end
		}

		return 0
	end

	def condensedFlowName(fullName)
		summFlow = ""
		lastFlow = ""
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
		return summFlow
	end

	def mapcreateFlow(mapflowList, flowList, h_id, newName)
		if mapflowList.length > 0
			# Map the flow id to existing one if it exists
			mappedFlowID = mapFlow(mapflowList)
			if mappedFlowID != 0
				puts '$$$$$$$$$$$$$$ MAPPED FLOW $$$$$$$$$$$$$$$$$$'
				puts mappedFlowID
				puts '$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$'
				test = TestCaseHeader.first_or_create(:id=>h_id)
				test.update(:flow_id => mappedFlowID,:temp_flow=>false)	
			else
				# Flow Creation
				i = 1
				appArray = Hash.new
				flowList.each do |app|
					appArray["#{i}"]= app
					i+=1
				end	

				newName = newName[0..newName.length - 4]
				newSMName = condensedFlowName(newName)
				puts appArray.inspect
				flow = createAppFlow(newName,newSMName,appArray,'SYSTEM')
				puts '@@@@@@@@@@@@@@ CREATED FLOW @@@@@@@@@@@@@@@@@'
				puts flow
				puts '@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@'
				test = TestCaseHeader.first_or_create(:id=>h_id)
				test.update(:flow_id =>flow,:temp_flow=>false)	
			end								
		end			
	end

	def detectUpdateCase(data, cur_row)
		mapflowList = Array.new
		flowList = Array.new
		testcasename = ''

		pos = 0
		addList = false

		data.each_key do |subitem|
			if subitem == 'case_data'
				data.each_value do |subitems|
					subitems.each_value do |sub|
						sub.each_value do |subs|
							# Flow Vars
							seq_id = subs[:'Application Index']
							appname = subs[:'Application Name']

							if seq_id != 'Application Index'
								# Get app info or create it if needed
								pro_id = appname.split(' - ').first
								app = appname.gsub(pro_id + ' - ', '')
								curapp = App.first(:project_id => pro_id)
								appid = curapp[:id]

								#  Start
								if pos == cur_row
									testcasename = subs[:'E2E Test Case Name']
									addList = true
								end

								# Stop
								if seq_id.to_i == 1 && pos > cur_row
									addList = false
									# puts '!!!!!!!!!!!!BING!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
								end

								# Get Middle rows
								if addList == true
									# Save the apps and sequence to check flow mapping and creation later
									mapflowList.push(seq_id + ',' + appid.to_s)
									# flowList.push(appid)
									# arrCombo = appname.split(' - ')
									# newName += arrCombo[1] + ' > '
								end	
							end

							pos = pos + 1
						end
					end		
				end
			end
		end

		puts '&*&*&*&*&*&*&*&*&*DETECT NEW CASE&*&*&*&*&*&*&*&*&*&*&*'

		# Check if there is a flow for this; get the id
		mapflowList = mapflowList.flatten
		# puts mapflowList.inspect

		mappedFlowID = mapFlow(mapflowList)

		puts mappedFlowID

		# Check if there is a test case with same case name and flow id
		tc = TestCaseHeader.first(:test_case_name => testcasename,:flow_id => mappedFlowID)

		puts tc.inspect

		if tc != nil
			tc_id = tc[:id]
		else
			tc_id = nil
		end		

		puts tc_id

		puts '&*&*&*&*&*&*&*&*&*&*&*&*&*&*&*&*&*&*&*&*'

		return tc_id
	end

	def detectUpdateHeader(solo_case_name, appname)
		# Get app info or create it if needed
		pro_id = appname.split(' - ').first
		app = appname.gsub(pro_id + ' - ', '')
		curapp = App.first(:project_id => pro_id)
		appid = curapp[:id]

		sc = SoloCaseHeader.first(:solo_case_name => solo_case_name, :app_id => appid)

		puts '!!!!!!!!!!!!!!!!!!UPDATE STEP HEADER DETECT!!!!!!!!!!!!!!!!!!!'
		# puts sc.inspect

		if sc != nil
			sc_id = sc[:id]
		else
			sc_id = nil
		end

		return sc_id

		puts '!!!!!!!!!!!!!!!!UPDATE STEP HEADER DETECT END!!!!!!!!!!!!!!!!!'

		# data.each_key do |subitem|
		# 	if subitem == 'step_data'
		# 		data.each_value do |subitems|
		# 			subitems.each_value do |sub|
		# 				sub.each_value do |subs|

		# 				end
		# 			end
		# 		end
		# 	end
		# end	

	end


	def detectUpdateStep(solo_case_id, step_id)
		scs = SoloCaseStep.first(:solo_case_header_id => solo_case_id, :step_id => step_id)

		puts '!!!!!!!!!!!!!!!!!!UPDATE STEP DETECT!!!!!!!!!!!!!!!!!!!'
		# puts sc.inspect

		if scs != nil
			scs_id = scs[:id]
		else
			scs_id = nil
		end

		return scs_id

		puts '!!!!!!!!!!!!!!!!UPDATE STEP DETECT END!!!!!!!!!!!!!!!!!'
	end	

	def getEmptyFlows(flow_name, app_name)
		fName_conditions = flow_name.split("|")
		aName_conditions = app_name.split("|")

		adapter = DataMapper.repository(:default).adapter
		sql = "SELECT flow_des FROM flows  
		INNER JOIN app_flow_rels ON app_flow_rels.flow_id = flows.id 
		INNER JOIN apps ON apps.id = app_flow_rels.app_id
		WHERE NOT EXISTS (SELECT 1 FROM test_case_headers WHERE test_case_headers.flow_id = flows.id AND  test_case_headers.temp_flow = 0)"

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

		# puts '##############################################'
		# puts sql
		# puts '##############################################'

		@result = adapter.select(sql)

		# Convert to a form that can be combined with the other search results
		conv_result = []
		@result.each { |item| 
			# Create a struct like the other one has?
			container = Struct.new(:flow_des, :id, :test_case_name, :test_case_type)
			items = container.new(item, "", "", "")

			conv_result.push(Hash[items.each_pair.to_a])
			# Hash["a", 100, "b", 200]
		}
		conv_result = conv_result.flatten.uniq
		@result = @result.flatten.uniq

		# puts '##############################################'
		# puts conv_result.inspect
		# puts '##############################################'	

		return conv_result
	end

end

class String
  def numeric?
    Float(self) != nil rescue false
  end
end