#coding = utf-8
class UsersController < ApplicationController
  before_filter :location, :only => [:near_me]
  before_filter :set_menu_active
  skip_before_filter :authenticate_user!, :only => [:iwant_user, :iwant_user_save]

	def show
		@user = User.find_by(:name => params[:id])
		@posts = Post.where(:user => @user).desc(:created_at).page(params[:page])
    @action_name = "show"
    set_seo_meta(@user.name)
    render  :action => "index"
 	end

 	def follow
      @user = User.find(params[:id])
      current_user.push_following(params[:id])
    	@user.push_follower(current_user.id)
      set_seo_meta(@user.name)
    	render :text => "1"
  end

  def unfollow
    	@user = User.find(params[:id])
      current_user.pull_following(params[:id])
    	@user.pull_follower(current_user.id)
      set_seo_meta(@user.name)
   		render :text => "1"
  end

  def index

  end

  def followers
    @user = User.find_by(:name => params[:id])
    set_seo_meta(@user.name)
    render  :action => "index"
  end

  def following
    @user = User.find_by(:name => params[:id])
    set_seo_meta(@user.name)
    render :action => "index"
  end

  def join_posts
    @user = User.find_by(:name => params[:id])
    @posts = @user.wish_posts.desc(:created_at).page(params[:page])
    set_seo_meta(@user.name)
    render :action => "index"
  end

  def complete_posts
    @user = User.find_by(:name => params[:id])
    @posts = @user.complete_posts.desc(:created_at).page(params[:page])
    set_seo_meta(@user.name)
    render :action => "index"
  end



  def near_me 
    unless params[:id].blank?
      session[:location] = Location.find_by(name: params[:id])
    end

    if  session[:gender].blank?
      session[:gender] = 1
    elsif params[:gender].blank?
      session[:gender] = 1
    else
       session[:gender] = params[:gender]
    end
    @users = User.where(location: session[:location], gender: session[:gender]).desc(:created_at).page(params[:page])
    render :action => "friends"
  end

  def iwant_user
    @apply_for_test = ApplyForTest.new
  end

  def iwant_user_save
    @apply_for_test = ApplyForTest.new(params[:apply_for_test])
    if @apply_for_test.save
      redirect_to "/users/iwant_user", notice: '你的申请已经成功，在验证信息后我们会发送一封邮件邀请你注册.' 
    else
      render :action => :iwant_user , error: '申请失败' 
    end
  end

  protected

    def set_menu_active
      @current = @current = ['/users/near_me']
    end



end
