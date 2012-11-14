#coding: utf-8
require "open-uri"  
class PostsController < ApplicationController
	before_filter :location, :only => [:index, :near_me, :tag]
	before_filter :set_menu_active

	DOUBAN_APIKEY = '0c4c24c38128d4df24e46e4a837a7e9d'
	DOUBAN_SECRET = 'd66f4058142d5c92'
	DOUBAN_ACCESS_TOKEN = '1bfe1241d8bdf5de53fa36c58a39e19a'

	def new	
		@post = Post.new
		set_seo_meta("借出图书")
	end


	def get_book
		@book = JSON.parse(open("http://api.douban.com/v2/book/isbn/#{params[:isbn]}?apikey=#{DOUBAN_APIKEY}&secret=#{DOUBAN_SECRET}").read)
		@sucess = true
		respond_to do |format|
			format.js { render :layout => false }
		end
		rescue OpenURI::HTTPError, Net::HTTPNotFound, Mechanize::ResponseCodeError
		@sucess = false	
		respond_to do |format|
			format.js { render :layout => false }
		end
	end

	def get_posts
		if params[:action_name] == "near_me"
			@posts = Post.where(location: session[:location]).desc(:created_at).page(params[:page])
			@action_name = "near_me"
		elsif params[:action_name] == "tag"
			@current_tag = Tag.find_by(:name => params[:id])
			@posts = @current_tag.posts.desc(:created_at).page(params[:page])
			@action_name = "tag"
		elsif params[:action_name] == "show"
			@account = User.find_by(:name => params[:id])
			@share_count = @account.posts.count
			@posts = Post.where(:account => @account).desc(:created_at).page(params[:page])
			@action_name = "show"
		else
			@posts = Post.desc(:created_at).page(params[:page])
			@action_name = "index"

		end
	end

	def index
		set_seo_meta("首页")
		@posts = Post.desc(:created_at).page(params[:page])
	end

	def near_me
		session[:location] = Location.find_by(name: params[:id])
		@posts = Post.where(location: session[:location]).desc(:created_at).page(params[:page])
		set_seo_meta("同城")
		render :action => "index"
	end

	def tag
		@current_tag = Tag.where(:name => params[:id]).first
		if @current_tag.blank?
			render_404
			return
		end
		@posts = @current_tag.posts.desc(:created_at).page(params[:page])
		set_seo_meta(@current_tag.name)
		render :action => "index"
	end


	def create 
		# unless params[:lat].blank?
		# 	params[:post][:coordinates] = [Float(params[:lat]),Float(params[:lng])]
		# 	doc = JSON.parse(open("http://ditu.google.cn/maps/geo?output=json&hl=zh_cn&q=#{params[:lat]},#{params[:lng]}").read)
		# 	address_path = JsonPath.new('$..address')
		# 	location_path = JsonPath.new('$..LocalityName')
		# 	params[:post][:address] = address_path.on(doc).first
		# 	params[:post][:location] = Location.where(name: location_path.on(doc).first[0,2]).first
		# end
		params[:post][:coordinates] = [Float(params[:lat]),Float(params[:lng])]
		params[:post][:address] = params[:address]
		params[:post][:location] = Location.where(name: params[:city][0,2]).first
		@post = Post.new(params[:post])
		if @post.location.blank?
			@post.errors[:location] = '暂时不支持该城市！更多城市会在公测后开放'
			render :action => :new 
			return
		end
		@post.remote_image_url = params[:post][:image]
		@post.user = current_user
		if @post.save
			redirect_to @post, notice: '操作成功.' 
		else
			render :action => :new ,alert: '你输入的数据有问题'
		end
	end



	def show
		@post = Post.where(:id => params[:id]).first
		if @post.blank?
			render_404
			return
		end
		@post.hits.incr(1)
		@comment = Comment.new
		set_seo_meta(@post.title)
		@nears = Post.near(:coordinates => @post.coordinates).desc(:created_at).limit(10)
	end

	def complete_wish
		@post = Post.find(params[:id])
		if @post.push_wish_user(current_user.id)
			current_user.push_wish_post(@post.id)
			@post.send_notification(Notification::TYPE[:join],current_user, @post.user,"我刚申请了想要借你本书")
			redirect_to @post, notice: '操作成功.' 
		else
			redirect_to @post, error: '已经添加过了' 
		end
	end

	def exec_user
		@post = Post.find(params[:id])
		if @post.complete_user?
			redirect_to @post, error: '当前任务已经有圆梦师了' 
		else
			@post.complete_user_id = params[:complete_user_id]
			@post.complete_user.push_complete_post(@post.id)
			@post.save
			@post.send_notification(Notification::TYPE[:complete_choose],@post.user,@post.complete_user,"我刚通过你的申请")
			redirect_to @post, notice: '操作成功.' 
		end		
	end

	def end_task
		@post = Post.find(params[:id])
		if @post.update_attributes(params[:post])
			@post.send_notification(Notification::TYPE[:complete],@post.user,@post.complete_user,"我刚给你评价:#{@post.rating_body}")
			redirect_to @post, notice: '操作成功.' 
		else
			redirect_to @post, notice: '操作失败.' 
		end



	end



	protected

  	def set_menu_active
    	@current = @current = ['/posts']
  	end



end
