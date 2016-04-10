class TankosController < ApplicationController

  def index
    @tankos = Tanko.all
  end

  def new
    @templates = Tanko.where(template: [true])
    @tanko = Tanko.new
  end

  def edit
    @tanko = Tanko.find(params[:id])
  end

  def show
    @tanko = Tanko.find(params[:id])
    @containers_list = @tanko.containers.all
    
    response = HTTParty.get('http://172.17.42.1:4001/v2/keys/contanko/tanko/36/fe')
    @body = JSON.parse(response.body)
    
     
   end

  def create
    @tanko = Tanko.new(tanko_params)
    if @tanko.save

    if tanko_params[:metadata].length > 1
       @tanko_template = Tanko.find(tanko_params[:metadata])
       @containers_list = @tanko_template.containers.all
       
       pass=nil
       dbserver=nil
       dp_ins_type=""
       @containers_list.each do |container_template|
        
    #@tanko = Tanko.find(params[:tanko_id])                                                                                                                                
                                                                                                                                                                           
    #cp = container_params                                                                                                                                                 
    #dp_ins_type=""                                                                                                                                                        
    #if params[:custom_image_name].length > 1                                                                                                                              
    #  cp[:image_name] = params[:custom_image_name]                                                                                                                        
    #end                                                                                                                                                                   
                                                                                                                                                                           
    #if container_params[:shared_vol].length > 1                                                                                                                           
    #@shared_vol = @tanko.containers.find(container_params[:shared_vol])                                                                                                   
    #cp[:shared_vol] = @tanko.id.to_s + @shared_vol.instance_name + @shared_vol.id.to_s                                                                                    
    #end                                                                                                                                                                   
                                                                                                                                                                           
    #if container_params[:depends_on].length > 1                                                                                                                           
    #@shared_vol = @tanko.containers.find(container_params[:depends_on])                                                                                                   
    #cp[:depends_on] = @tanko.id.to_s + @shared_vol.instance_name + @shared_vol.id.to_s                                                                                    
    #dp_ins_type=@shared_vol.instance_type.to_s                                                                                                                            
    #end                                                                                                                                                                   
                                                                                                                                                                           
    #@container = @tanko.containers.create("instance_name"=>container_template.instance_name, "description"=>"", "instance_type"=>container_template.instance_type)                                                                                                              
    if pass.nil? then
    pass = (0...8).map { (65 + rand(26)).chr }.join
    end 
    
    if container_template.depends_on.length > 1
      container_template.depends_on = dbserver
    else
      dp_ins_type=""
    end 
    #if container_template.image_name.include? "mysql" then
    #dbserver = @tanko.id.to_s + container_template.instance_name +
    #end

    #sentence.sub! 'Robert', 'Joe'
    
    #container_template.env_vars    

    envs = container_template.env_vars

    envs.sub! 'mypass', pass
    
    if envs.include? "WORDPRESS_DB_HOST" then
    envs.sub! 'WORDPRESS_DB_HOST=$(etcdctl get /contanko/tanko/14/be/14mysql01109-ip)', 'WORDPRESS_DB_HOST=$(etcdctl get /contanko/tanko/' + @tanko.id.to_s + '/be/' + dbserver + '-ip)'
    end

    @container = @tanko.containers.create("instance_name"=>container_template.instance_name, "description"=>container_template.description, "instance_type"=>container_template.instance_type, "env_vars"=>envs, "image_name"=>container_template.image_name, "instance_link"=>container_template.instance_link, "shared_vol"=>container_template.shared_vol, "depends_on"=>container_template.depends_on, "ports"=>container_template.ports) 
     
    DeployContainer01.perform_async(@container.id.to_s,@tanko.id.to_s,@container.instance_name,@container.description,@container.instance_type,@container.image_name,@container.env_vars,@container.instance_link,@container.ports,@container.shared_vol,@container.depends_on,dp_ins_type)
    

    if container_template.image_name.include? "mysql" then
      dbserver = @tanko.id.to_s + container_template.instance_name + @container.id.to_s
      dp_ins_type = container_template.instance_type
    end
                                                                                                                                                                  
    #cell = Result.new(cell_name: filenames, icorrelation: intensities)                                                                                                    
    #cell.save!                                                                                                                                                            
                                                                                                                                                                           
                                                                                                                                                                          
    # DeployContainer01.perform_async(@container.id.to_s,@tanko.id.to_s,@container.instance_name,@container.description,@container.instance_type,@container.image_name,@container.env_vars,@container.instance_link,@container.ports,@container.shared_vol,@container.depends_on,dp_ins_type)
 
    #redirect_to tanko_path(@tanko)                                                                                                                                        
                                                                                                                                                                           
       end                                                                                                                                                                 
                                                                                                                                                                           
                                                                                                                                                                           
      end 

    redirect_to @tanko
    else
    render'new'
    end
  end

  def update
    @tanko = Tanko.find(params[:id])
    if @tanko.update(tanko_params)
      
      #if params[:metadata].length > 1
      # @tanko_template = Tanko.find(tanko_params[:metadata])
      # @containers_list = @tanko_template.containers.all 

      # @containers_list.each do |container_template|
        

       #@container = @tanko.containers.create(container_template)
           
      
      redirect_to @tanko
    else
      render 'edit'
    end
  end

  def destroy
    @tanko = Tanko.find(params[:id])
    @tanko.destroy
 
    redirect_to tankos_path
  end

private
  def tanko_params
    params.require(:tanko).permit(:service_name, :description, :metadata, :template)
  end
end

