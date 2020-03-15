# Set up for the application and database. DO NOT CHANGE. #############################
require "sinatra"                                                                     #
require "sinatra/reloader" if development?                                            #
require "sequel"                                                                      #
require "logger"                                                                      #
require "twilio-ruby"                                                                 #
require "bcrypt"                                                                  #
connection_string = ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite3"  #
DB ||= Sequel.connect(connection_string)                                              #
DB.loggers << Logger.new($stdout) unless DB.loggers.size > 0                          #
def view(template); erb template.to_sym; end                                          #
use Rack::Session::Cookie, key: 'rack.session', path: '/', secret: 'secret'           #
before { puts; puts "--------------- NEW REQUEST ---------------"; puts }             #
after { puts; }                                                                       #
#######################################################################################

locations_table = DB.from(:locations)
users_table = DB.from(:users)
graffiti_table = DB.from(:graffiti)
@gmaps_apikey = "AIzaSyCtovsQvkIUWlNqtYwXY87gEd4ZSmJEhMw"

#Twilio API keys
account_sid = ENV["TWILIO_ACCOUNT_SID"]
auth_token = ENV["TWILIO_AUTH_TOKEN"]
client = Twilio::REST::Client.new(account_sid, auth_token)

before do
    @current_user = users_table.where(id: session["user_id"]).to_a[0]
    puts "current user: #{@current_user}"
end

get "/" do
    puts "params: #{params}"

    @locations = locations_table.all.to_a
    pp @locations
    pp @current_user

    view "locations"
end

# display the signup form (aka "new")
get "/users/new" do
    view "new_user"
end

# receive the submitted signup form (aka "create")
post "/users/create" do
    puts "params: #{params}"

    # if there's already a user with this email, skip!
    existing_user = users_table.where(email: params["email"]).to_a[0]
    if existing_user
        view "error"
    else
        users_table.insert(
            username: params["username"],
            email: params["email"],
            telephone: "+1#{params["telephone"]}",
            password: BCrypt::Password.create(params["password"])
        )
        client.messages.create(
        from: "+14707190684", 
        to: "+16174069139",
        body: "Thanks for signing up!"
        )
        redirect "/logins/new"
    end
end

# display the login form (aka "new")
get "/logins/new" do
    view "new_login"
end

# receive the submitted login form (aka "create")
post "/logins/create" do
    puts "params: #{params}"

    # step 1: user with the params["email"] ?
    @user = users_table.where(email: params["email"]).to_a[0]

    if @user
        # step 2: if @user, does the encrypted password match?
        if BCrypt::Password.new(@user[:password]) == params["password"]
            # set encrypted cookie for logged in user
            session["user_id"] = @user[:id]
            redirect "/"
        else
            view "create_login_failed"
        end
    else
        view "create_login_failed"
    end
end

# logout user
get "/logout" do
    # remove encrypted cookie for logged out user
    session["user_id"] = nil
    redirect "/logins/new"
end

#show location details
get "/locations/:id" do
    puts "params: #{params}"

    @users_table = users_table
    @location = locations_table.where(id: params[:id]).to_a[0]
    #graffiti_table = graffiti_table.order(Sequel.desc(:graffitiyear, :graffitimonth))
    #@graffiti = graffiti_table.where(location_id: params["id"]).order(Sequel.desc(:graffitimonth, :graffitiday)).to_a[0]
    #graffiti_table = graffiti_table.reload
    @graffiti = graffiti_table.to_a[0]

    pp @graffiti
    pp @location

    #@rsvps = rsvps_table.where(event_id: @event[:id]).to_a
    #@going_count = rsvps_table.where(event_id: @event[:id], going: true).count

    view "location"
end

get "/locations/:id/graffiti/new" do
    puts "/graffiti/new params: #{params}"
    
    @users_table = users_table
    @location = locations_table.where(id: params["id"]).to_a[0]
    #graffiti_table = graffiti_table.order(Sequel.desc(:graffitiyear, :graffitimonth))
    #@graffiti = graffiti_table.where(location_id: params["id"]).order(Sequel.desc(:graffitimonth, :graffitiday)).to_a[0]

    @graffiti = graffiti_table.where(location_id: params["id"]).to_a[0]


    pp @graffiti
    pp @location

    view "new_graffiti"
end

post "/locations/:id/graffiti/create" do
    puts "/graffiti/create params: #{params}"

    #create new entry in graffiti table
    if params["anonymous"] == "on" then
        anonymous_tempvar = 1
    else
        anonymous_tempvar = 0
    end
    time = Time.new
    graffiti_table.insert(user_id: @current_user[:id],
                    location_id: params["id"],
                    graffiti: params["graffiti"],
                    graffitiyear: time.year,
                    graffitimonth: time.month,
                    graffitiday: time.day,
                    anonymous: anonymous_tempvar
    )

    redirect "/locations/#{@params["id"]}"

end