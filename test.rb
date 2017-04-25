require "parseexcel/parser"
require "mysql"


# A Postgres connection:
#ENV['DATABASE_URL']
#ENV['HEROKU_POSTGRESQL_NAVY_URL']
#DataMapper.setup(:default, ENV['HEROKU_POSTGRESQL_NAVY_URL'] ||'postgres://postgres:postgres@localhost/postgres')
puts 'asdf'

def read_excel(excel)
	require 'win32ole'
	require 'pp'
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
ensure
	workbook.close unless workbook.nil?
end

# def readExcel()
# 		workbook = Spreadsheet::ParseExcel::Parser.new.parse("C:/ruby.xls")
# 		worksheet = workbook.worksheet(0)
# 		#遍历该行非空单元格
# 		j=0  # initialize row
# 		worksheet.each do |row|
# 			i=0	 # initialize cell
# 			if row !=nil then
# 				row.each do |cell|
# 					if cell !=nil then
# 						contents = cell.to_s('utf-8')
# 						puts "Row: #{j} Cell: #{i} #{contents}"
# 					end
# 				i+=1
# 				end	
# 			end
# 			j+=1
# 		end
# 	end

read_excel('ruby.xlsx')
#p readExcel