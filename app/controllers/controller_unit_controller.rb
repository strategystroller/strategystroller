class ControllerUnitController < ApplicationController
  require 'base64' 
  before_filter :authenticate_user!
  #before_filter do
  # #should handle checking that a user is a cu, as of yet untested TODO test me.
    #redirect_to :new_user_session_path unless current_user && current_user.controlling_unit?
  #end

  ## INFO
  GOAL = 1
  INDICATOR = 2
  PROJECT = 3
  ACTIVITY = 4

  def controller_panel
    @user = current_user
  end
  
  def set_goal
    @goal = Goal.new
    if (request.post?) 
      @goal = Goal.new(params[:goal])
      if @goal.save
        result = save_form(GOAL, @goal.user_id, @goal.id)
        if result.include? "ERROR"
          flash[:error] = result
        else
          flash[:notice] = "Goal successfully saved!"
        end
      else
        flash[:error] = "ERROR: Goal was not saved!"
      end
      redirect_to goals_path
    end
  end
  
  def set_indicator
    @indicator = Indicator.new
    if (request.post?) 
      @indicator = Indicator.new(params[:indicator])
      if @indicator.save
        result = save_form(INDICATOR, @indicator.user_id, @indicator.id)
        if result.include? "ERROR"
          flash[:error] = result
        else
          flash[:notice] = "Indicator successfully saved!"
        end
      else
        flash[:error] = "ERROR: Indicator was not saved!"
      end
      redirect_to indicators_path
    end
  end
  
  def set_project
    @project = Project.new
    if (request.post?) 
      @project = Project.new(params[:project])
      if @project.save
        result = save_form(PROJECT, @project.head_id, @project.id)
        if result.include? "ERROR"
          flash[:error] = result
        else
          flash[:notice] = "Project successfully saved!"
        end
      else
        flash[:error] = "ERROR: Project was not saved!"
      end
      redirect_to projects_path
    end
  end
  
  def set_activity
    @activity = Activity.new
    if (request.post?) 
      @activity = Activity.new(params[:activity])
      if @activity.save
        # Assume current user is Provider for now
        result = save_form(ACTIVITY, current_user.id, @activity.id)
        if result.include? "ERROR"
          flash[:error] = result
        else
          flash[:notice] = "Activity successfully saved!"
        end
      else
        flash[:error] = "ERROR: Activity was not saved!"
      end
      redirect_to activities_path
    end
  end
  
  def applications
    @application = Application.new
    if (request.post?)
      if (params[:commit] == 'Save Setup')
          redirect_to "/controller_unit/setup_system"
          setup_system
      elsif (params[:commit] == 'Create User(s)')
          redirect_to "/controller_unit/create_users"
          create_users
      elsif (params[:commit] == 'Remove User(s)')
          redirect_to "/controller_unit/remove_users"
          remove_users
      end
    end
  end
  
    def setup_system
        @application = Application.new
        @years = Application::YEARS
        @languages = Application::LANGUAGES
        @time_horizon = Application::TIME_HORIZON
         if (request.post?) 
            @application = Application.new(params[:application])
            @user_obj = User.new(:username=>"username2342")
            @form_url = "google.com"
            FormMailer.form_email(@user_obj,@form_url).deliver
            if @application.save
                flash[:notice] = "Setup successfully saved!"
            else
                flash[:error] = "ERROR: Setup was not saved"
                return
            end
        end
    end

    def encode_id(form_id)
      encoded = Base64.encode64(form_id.to_s)
      return encoded
    end

    def encode_url(form_id)
      encoded_id = encode_id(form_id.to_s)
      url = "http://localhost:3000/form_id=" + encoded_id.to_s
    end

    def decode_id(form_id)
      decoded = Base64.decode64(form_id.to_s)
      return decoded
    end

    def extract_id(url)
      id = url.split("form_id=")[1]
      return id
    end  


    def create_users
       @application = Application.new #Just using Application model because it has a 'users' field that cocoon needs
        if (request.post?)
            app = params[:application]
            if (app != nil)
                users_hash = app[:users_attributes] #hash of hashes

                numSaved = 0 
                total = 0 #number of users that should be saved
                notSaved = []

                users_hash.each do |key, value|
                    username = users_hash[key][:username]
                    email = users_hash[key][:email]
                    if (email != "" && username != "") #quick check not from empty input boxes (or invalid)
                        total += 1
                      
                        temp_password = SecureRandom.hex
                        cu = users_hash[key][:controlling_unit]
                        user = User.new(:username => username, :email => email, :password => temp_password, :temp_password => temp_password, :controlling_unit => cu)
                        if user.save
                            numSaved += 1
                        else
                            notSaved << email
                        end
                    end
                end     

                if (numSaved == 0 && total == 0) #empty input boxes
                    flash[:notice] = "Please enter Username and Email"
                elsif (numSaved == total) #tried to save valid inputs and success!
                    flash[:notice] = "All users successfully saved!"
                else #some users could not be saved
                    user_string = ""
                    notSaved.each do |user|
                        user_string = user_string + user + ", "
                    end
                    user_string.slice!(user_string.length - 2)
                    flash[:notice] = "User(s) " + user_string + "already exist(s). All other users successfully created!"
                end
            else
                flash[:notice] = "No users saved"
            end
         end
    end

    def remove_users
         @application = Application.new #Just using Application model because it has a 'users' field that cocoon needs
        if (request.post?)
            app = params[:application]
            if (app != nil)
                users_hash = app[:users_attributes] #hash of hashes

                numDeleted = 0 
                total = 0 #number of users that should be deleted
                notDeleted = []
                #here
                users_hash.each do |key, value|
                    email = users_hash[key][:email]
                    if (email != "") #quick check not from empty input boxes (or invalid)
                        total += 1
                        user = User.find_by_email(email)

                        if (user) #user with this email exists
                          User.delete(user)
                          if (!User.find_by_email(email)) #not successfully deleted, perhaps redundant check
                              numDeleted += 1
                          else
                              notDeleted << email
                          end
                        else
                          notDeleted << email
                        end
                    end

                end     

                if (numDeleted == 0 && total == 0) #empty input boxes
                    flash[:notice] = "Please enter Username and Email"
                elsif (numDeleted == total) #tried to delete valid inputs and success!
                    flash[:notice] = "All users successfully removed!"
                else #some users could not be deleted
                    user_string = ""
                    notDeleted.each do |user|
                        user_string = user_string + user + ", "
                    end
                    user_string.slice!(user_string.length - 2)
                    flash[:notice] = "User(s) " + user_string + "do(es) not exist. All other users successfully removed!"
                end
            else
                flash[:notice] = "No users removed"
            end
         end
    end

  def save_form(table_id, user_id, entry_id)
    default = [GOAL,INDICATOR,PROJECT,ACTIVITY]
    if default.include? table_id
      @form = create_form(false, table_id, false, user_id, false, Date.current, entry_id)
      if @form.save
        return "Form successfully saved!"
      else
        return "ERROR: Form cannot be saved!"
      end
    else
      # ERROR: wrong table_id
      return "ERROR: Wrong table id!"
    end
  end

  def create_form(checked, table_id, reviewed, user_id, submitted, last, entry_id)
    form = Form.new(
    :checked => checked,
    :lookup => table_id,
    :reviewed => reviewed,
    :user_id => user_id,
    :submitted => submitted,
    :last_reminder => last,
    :entry_id => entry_id
    )
    return form
  end


  def cu_review
    if (request.post?) 
      Form.find_by_checked_and_reviewed_and_submitted(true, false, true)
      #get a list of forms that have been submitted, not reviewed, checked (by provider)
      #for each form
      #generate the link to the form -- for now, just 
    end
  end


end
