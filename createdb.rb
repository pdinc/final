# Set up for the application and database. DO NOT CHANGE. #############################
require "sequel"                                                                      #
connection_string = ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite3"  #
DB = Sequel.connect(connection_string)                                                #
#######################################################################################

# Database schema - this should reflect your domain model
DB.create_table! :users do
  primary_key :id
  String :username
  String :email
  String :telephone
  String :password
end
DB.create_table! :locations do
  primary_key :id
  String :placename
  String :gmapsplaceid
  Fixnum :zipcode
end
DB.create_table! :graffiti do
  primary_key :id
  foreign_key :user_id
  foreign_key :location_id
  String :graffiti
  Fixnum :graffitiyear
  Fixnum :graffitimonth
  Fixnum :graffitiday
  Fixnum :anonymous
end

# Insert initial (seed) data for locations
locations_table = DB.from(:locations)

locations_table.insert(placename: "Wieboldt Hall",
                    gmapsplaceid: "ChIJ1STroD0pDogR5cNexT86gbs", 
                    zipcode: 60611
)

locations_table.insert(placename: "Global Hub",
                    gmapsplaceid: "ChIJmWd1cp7aD4gRzYzB_KYoiu4", 
                    zipcode: 60208
)

# Insert initial (seed) data for graffiti
graffiti_table = DB.from(:graffiti)

graffiti_table.insert(user_id: 1,
                    location_id: 1,
                    graffiti: "Kilroy was here",
                    graffitiyear: 2020,
                    graffitimonth: 3,
                    graffitiday: 15,
                    anonymous: 1
)

graffiti_table.insert(user_id: 1,
                    location_id: 1,
                    graffiti: "Pavan was here too",
                    graffitiyear: 2020,
                    graffitimonth: 3,
                    graffitiday: 15,
                    anonymous: 0
)