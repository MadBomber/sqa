# lib/sqa/datastore/csv/yahoo_finance.rb

# processes a CSV file downloaded from finance.yahoo.com
# Date,Open,High,Low,Close,Adj Close,Volume

require 'csv-importer'

class SQA::Datastore::CSV::YahooFinance
  include CSVImporter

  model ::SQA::Activity # an active record like model

	column :date,  			to: ->(x) { Date.parse(x)},	required: true
	column :open,  			to: ->(x) {x.to_f},					required: true
	column :high,  			to: ->(x) {x.to_f},					required: true
	column :low,  			to: ->(x) {x.to_f},					required: true
	column :close,  		to: ->(x) {x.to_f},					required: true
	column :adj_close, 	to: ->(x) {x.to_f},					required: true
	column :volumn,  		to: ->(x) {x.to_i},					required: true

	# TODO: make the identifier compound [ticker, date]
	# 			so we can put all the data into a single table.

	identifier :date

	when_invalid :skip # or :abort


  column :email, 			to: ->(email) { email.downcase }, required: true
  column :first_name, as: [ /first.?name/i, /pr(é|e)nom/i ]
  column :last_name,  as: [ /last.?name/i, "nom" ]
  column :published,  to: ->(published, user) { user.published_at = published ? Time.now : nil }




  def self.load(ticker)
		import = new(file: "#{ticker.upcase}.csv")

		import.valid_header?  # => false
		import.report.message # => "The following columns are required: email"

		# Assuming the header was valid, let's run the import!

		import.run!
		import.report.success? # => true
		import.report.message  # => "Import completed. 4 created, 2 updated, 1 failed to update"  end

	end
end

