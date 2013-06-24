# encoding: UTF-8

class PlantsController < ApplicationController

  before_filter :admin_user, only: [:new, :create, :update, :destroy, :edit]

  #respond_to :html, :xml, :json

  def show
    @plant = Plant.find(params[:id])
  end

  def index
    respond_to do |format|

      @plants = Plant.order('name ASC').paginate(page: params[:page])
      format.html { render :html => @plants } # index.html.erb
      if params[:page].present?
        @jsonPlants = Plant.order('name ASC').paginate(page: params[:page], per_page: params[:per_page])
      else
        @jsonPlants = Plant.all
      end

      @jsonPlantsDub = [:Plant]

      if params[:name].present?
        @jsonPlants.each do |p|
          if !p.name.downcase.include?(params[:name].downcase)
            @jsonPlantsDub << p
          end
        end
      end

      @jsonPlants -= @jsonPlantsDub
      format.json { render :json => {admin: admin?, count: @plants.total_entries, plants: @jsonPlants} }
    end
  end

  def new
    @plant = Plant.new
  end

  def edit
    @plant = Plant.find(params[:id])
  end

  def create
    @plant = Plant.new(params[:plant])

    params[:colour][:id].shift

    if not params[:colour][:id].empty?
      params[:colour][:id].each do |col|
        @col = Colour.find_by_id col
        if not @col.equal? nil
          @plant.colours << @col
        end
      end
    end

    @plant.light = Light.find_by_id(params[:light][:id])


    if params[:maintenances][:id]
      @plant.maintenance = Maintenance.find_by_id(params[:maintenances][:id])
    end

    if @plant.save
      if @plant.light_id.nil?
        @plant.update_attribute(:light_id, 1)
      end
      params[:growth_environments][:id].shift
      if (!params[:growth_environments][:id].empty?)
        params[:growth_environments][:id].each do |env|
          @env = GrowthEnvironment.find_by_id(env)
          if (@env != nil)
            @plant.growth_environments << @env
          end
        end
      end
      flash[:success] = "Kasvin lisäys onnistui!"
      redirect_to plants_url
    else
      render 'new'
    end
  end

  def update
    @plant = Plant.find(params[:id])

    params[:growth_environments][:id].shift
    if (!params[:growth_environments][:id].empty?)
      @plant.growth_environments.clear
      params[:growth_environments][:id].each do |env|
        @env = GrowthEnvironment.find_by_id(env)
        if (@env != nil)
          @plant.growth_environments << @env
        end
      end
    else
      @plant.growth_environments.clear
    end

    if params[:maintenances][:id]
      @plant.maintenance = Maintenance.find_by_id(params[:maintenances][:id])
      @plant.save!
    end

    if @plant.update_attributes(params[:plant]) && @plant.update_attribute(:light_id, params[:light][:id])
      redirect_to plant_url
    else
      render 'edit'
    end
  end

  def destroy
    respond_to do |format|
      if Plant.find(params[:id]).destroy
        @response = "success"
      else
        @response = "error"
      end
      format.json { render :json => {response: @response} }
    end
    #render :nothing => true
  end

  def search
    respond_to do |format|

      format.html { render :html => {plants: @plants} }

      @plants = Plant.scoped

      @plants = @plants.where('name like ?', '%' + params[:name].downcase + '%') if params[:name]
      @plants = @plants.where('latin_name like ?', '%' + params[:latin_name].downcase + '%') if params[:latin_name]
      @plants = @plants.where('min_soil_thickness > ?', params[:min_thickness]) if params[:min_thickness]
      @plants = @plants.where('min_soil_thickness < ?', params[:max_thickness]) if params[:max_thickness]

      @plants = @plants.where('max_height <= ?', params[:max_height]) if params[:max_height]
      @plants = @plants.where('min_height >= ?', params[:min_height]) if params[:min_height]
      @plants = @plants.where('weight <= ?', params[:max_weight]) if params[:max_weight]
      @plants = @plants.where('weight >= ?', params[:min_weight]) if params[:min_weight]

      params[:colour].try(:each) do |colour|
        @plants = @plants.where('colour like?', '%' + colour.force_encoding('iso-8859-1').encode('utf-8') + '%') if colour
      end

      params[:growth_environments].try(:each) do |env|
        @plants = @plants.where('growth_environment like?', '%' + env.force_encoding('iso-8859-1').encode('utf-8') + '%') if env
      end

      if (params[:maintenance])
        @maints = []
        Maintenance.where(:name => params[:maintenance]).each do |id|
          @maints.push(id)
        end
        @plants = @plants.where(:maintenance_id => @maints)
      end

      if (params[:lightness])
        @lights = []
        Light.where(:desc => params[:lightness]).each do |id|
          @lights.push(id)
        end
        @plants = @plants.where(:light_id => @lights)
      end

      @plants = @plants.paginate(page: params[:page], per_page: params[:per_page]) unless @plants.nil?
      format.json { render :json => {admin: admin?, count: @plants.total_entries, plants: @plants} }
    end
  end
end
