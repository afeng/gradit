class Search < ActiveRecord::Base
	
	def self.search(query)
		@contexts = Array.new()
		la = BookLine.find(:all, :conditions => ["line like ?", "%" + query + "%"])

		reg = /\b#{query}\b/i
		
		for line in la do
			if (reg.match(line)) do
				beforeline = BookLine.find(:first, :conditions => ["linenum = ? and source = ?", line.linenum - 1, line.source])
				afterline = BookLine.find(:first, :conditions => ["linenum = ? and source = ?", line.linenum + 1, line.source])
				if (beforeline != nil) then beforeline = beforeline.line end
				if (afterline != nil) then afterline = afterline.line end
				bookname = Book.find(line.source).name
				if (line != nil) then linecontent = line.line end
				@contexts << [beforeline, linecontent, afterline, bookname]
			end
		end
		return @contexts
	end
end
