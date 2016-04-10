class ContainersController < ApplicationController

  def create
    @tanko = Tanko.find(params[:tanko_id])
   
    cp = container_params
    dp_ins_type="" 
    if params[:custom_image_name].length > 1
      cp[:image_name] = params[:custom_image_name]
    end
   
    if container_params[:shared_vol].length > 1 
    @shared_vol = @tanko.containers.find(container_params[:shared_vol])
    cp[:shared_vol] = @tanko.id.to_s + @shared_vol.instance_name + @shared_vol.id.to_s
    end

    if container_params[:depends_on].length > 1
    @shared_vol = @tanko.containers.find(container_params[:depends_on])
    cp[:depends_on] = @tanko.id.to_s + @shared_vol.instance_name + @shared_vol.id.to_s
    dp_ins_type=@shared_vol.instance_type.to_s
    end

    @container = @tanko.containers.create(cp)
    

    DeployContainer01.perform_async(@container.id.to_s,@tanko.id.to_s,container_params[:instance_name],container_params[:description],container_params[:instance_type],cp[:image_name],container_params[:env_vars],container_params[:instance_link],container_params[:ports],cp[:shared_vol],cp[:depends_on],dp_ins_type)

    redirect_to tanko_path(@tanko)
  end

  def start
    @tanko = Tanko.find(params[:tanko_id])                                                                                                                                 
    @container = @tanko.containers.find(params[:id]) 

    StartContainer01.perform_async(@container.id.to_s,@tanko.id.to_s,@container.instance_name,@container.description,@container.instance_type,@container.image_name,@container.env_vars,@container.shared_vol)
  
    @container.update_attribute(:status,"Running")

    redirect_to tanko_path(@tanko)
  end
  
  def stop
    @tanko = Tanko.find(params[:tanko_id])                                                                                                                                 
    @container = @tanko.containers.find(params[:id]) 

    StopContainer01.perform_async(@container.id.to_s,@tanko.id.to_s,@container.instance_name,@container.description,@container.instance_type,@container.image_name,@container.env_vars,@container.shared_vol)
     
    @container.update_attribute(:status,"Stopped") 
  
    redirect_to tanko_path(@tanko)
  end

  def destroy
    @tanko = Tanko.find(params[:tanko_id])
    @container = @tanko.containers.find(params[:id])

    DestroyContainer01.perform_async(@container.id.to_s,@tanko.id.to_s,@container.instance_name,@container.description,@container.instance_type,@container.image_name,@container.env_vars,@container.shared_vol)

    @container.destroy
    redirect_to tanko_path(@tanko)
  end
 
  private
    def container_params
       params.require(:container).permit(:instance_name, :description, :instance_type, :image_name, :env_vars, :instance_link, :custom_image_name, :ports, :shared_vol, :depends_on)
    end

end
