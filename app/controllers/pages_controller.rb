class PagesController < ApplicationController
  before_action :authenticate_user!, only: [
    :inside
  ]

  def home
    @tankos = Tanko.all
    @count_tankos = Tanko.group('date(created_at)').count
    @containers = Container.all
    @templates = Tanko.where(template: [true])
    @count_containers = Container.group('date(created_at)').count 
    @count_containers_images = Container.group('image_name').count

    #@container_stats = Container.group('image_name').count
    
    #@container_stats.each do |cs|
    #@c_stats << {
    # :value => cs.image_name,
    # :type => cs.instance_type,
    # :color => "#C7604C"
   #}
   #end
    
   # @project.line_items.group(:device_id).count
   @container_stats3 = @containers.group(:image_name).count

   @container_stats = @containers.group(:image_name).count


   @c_stats = @container_stats.map do |key, value|
    {
    :value => value,
    :label => key,
    :color => "#4DAF7C",
    :highlight => "#55BC75"
    #puts key
    #puts value
   }
   end

    @container_stats = Container.all

    @c_stats2 = @container_stats.map do |u|
     { 
      :value => u.image_name, 
    #  #:type => u.instance_type, 
      :color => "#C7604C" }
   end

    #@c_stats.to_json
    #@c_stats = @containers.group(:image_name).count

  end

  def inside
  end
  
def posts
    @posts = Post.published.page(params[:page]).per(10)
  end

  def show_post
    @post = Post.friendly.find(params[:id])
  rescue
    redirect_to root_path
  end

  
  def email
    @name = params[:name]
    @email = params[:email]
    @message = params[:message]

    if @name.blank?
      flash[:alert] = "Please enter your name before sending your message. Thank you."
      render :contact
    elsif @email.blank? || @email.scan(/\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i).size < 1
      flash[:alert] = "You must provide a valid email address before sending your message. Thank you."
      render :contact
    elsif @message.blank? || @message.length < 10
      flash[:alert] = "Your message is empty. Requires at least 10 characters. Nothing to send."
      render :contact
    elsif @message.scan(/<a href=/).size > 0 || @message.scan(/\[url=/).size > 0 || @message.scan(/\[link=/).size > 0 || @message.scan(/http:\/\//).size > 0
      flash[:alert] = "You can't send links. Thank you for your understanding."
      render :contact
    else
      ContactMailer.contact_message(@name,@email,@message).deliver_now
      redirect_to root_path, notice: "Your message was sent. Thank you."
    end
  end

end
