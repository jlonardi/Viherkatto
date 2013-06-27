# encoding: UTF-8

require 'RMagick'

class GreenroofsController < ApplicationController

  before_filter :signed_user, only: [:new, :create]


  def search

    respond_to do |format|

      format.html { render :html => {greenroofs: @greenroofs} }

      # --- Takes the Greenroof relation into a variable
      @greenroofs = Greenroof.scoped

      # --- Checks the search params and eliminates all non-matches

      # --- General (Yleiset)
      if params[:address]
        address = "%#{params[:address]}%"
        @greenroofs = @greenroofs.where("address like ?", address)
      end
      if params[:locality]
        locality = "%#{params[:locality]}%"
        @greenroofs = @greenroofs.where("locality like ?", locality)
      end
      if params[:envname]
        envname = "%#{params[:envname]}%"
        @greenroofs = @greenroofs.joins(:roof).joins(:roof => :environments).where("environments.name like ?", envname)
      end

      # --- Plants' attributes (Kasvien ominaisuudet)
      if params[:plantname]
        plantname = "%#{params[:plantname]}%"
        @greenroofs = @greenroofs.joins(:plants).where("plants.name like ?", plantname)
      end

      #add colours search

      if params[:maintenance]
        maintenance = params[:maintenance].to_i
        @greenroofs = @greenroofs.joins(:plants).where("plants.maintenance = ?", maintenance)
      end
      @greenroofs = @greenroofs.joins(:plants).where("plants.max_height <= ?", params[:plantmaxheight]).uniq if params[:plantmaxheight]
      @greenroofs = @greenroofs.joins(:plants).where("plants.min_height >= ?", params[:plantminheight]).uniq if params[:plantminheight]

      # --- Build's properties (Rakenteen ominaisuudet)
      @greenroofs = @greenroofs.joins(:bases).where("bases.absorbancy >= ?", params[:minabsorbancy]) if params[:minabsorbancy]
      @greenroofs = @greenroofs.joins(:roof).where("roofs.area <= ?", params[:maxroofarea]) if params[:maxroofarea]
      @greenroofs = @greenroofs.joins(:roof).where("roofs.area >= ?", params[:minroofarea]) if params[:minroofarea]
      @greenroofs = @greenroofs.joins(:roof).where("roofs.load_capacity >= ?", params[:minload_capacity]) if params[:minload_capacity]


      @greenroofs = @greenroofs.paginate(page: params[:page], per_page: params[:per_page]) unless @greenroofs.nil?
      @count = @greenroofs.total_entries


      #@greenroofs = @greenroofs.joins(:bases).where("bases.absorbancy >= ?", params[:minabsorbancy]) if params[:minabsorbancy]
      #@greenroofs = @greenroofs.joins(:layers).sum("layers.thickness => ?", params[:minthickness]) if params[:minthickness]


      @jsonGreenroofs = []

      @greenroofarray = @greenroofs.to_a
      @greenroofarray.each do |groof|
        @user = User.find_by_id(groof.user_id)
        jsonGreenroof = groof.attributes
        jsonGreenroof[:user] = @user.name
        @jsonGreenroofs << jsonGreenroof
      end

      format.json { render :json => {admin: admin?, count: @count, greenroofs: @jsonGreenroofs} }

    end

  end

  def show
    @greenroof = Greenroof.find(params[:id])
  end


  def new
    @greenroof = Greenroof.new
    @base = Base.new
    @layer = Layer.new

    @base.layers << @layer

    @roof = Roof.new
    @greenroof.bases << @base
    @greenroof.roof = @roof
    @environments = Environment.all
  end

  def create

    @greenroof = Greenroof.new(params[:greenroof])
    @greenroof.user = current_user


    @roof = Roof.new(params[:roof])

    if not params[:purpose].nil?
      params[:purpose].each do |purp|
        purp[1].each do |toAddPurp|
          @purp = Purpose.find(toAddPurp)
          if (@purp != nil)
            @greenroof.purposes << @purp
          end
        end
      end
    end

    if not params[:environment].nil?
      params[:environment][:id].shift
      params[:environment][:id].each do |env|
        @env = Environment.find_by_id(env)
        if (@env != nil)
          @roof.environments << @env
        end
      end
    else
      flash.now[:error] = "Et valinnut ympäristöä."
      respond_to do |format|
        #format.js { render :action => 'new' }
      end
      return
    end

    if params[:role].nil?
      flash.now[:error] = "Et valinnut roolia."
    elsif params[:role][:value] === "Valitse rooli"
      flash.now[:error] = "Et valinnut roolia."
    else
      @greenroof.role = Role.where("value like ?", params[:role][:value]).first
    end

    if not params[:customPlants].nil?
      params[:customPlants].each do |cplant|
        cplant[1].each do |toAddPlant|
          @cplant = CustomPlant.new(name: toAddPlant)
          @greenroof.custom_plants << @cplant
        end
      end
    end

    @greenroof.roof = @roof

    @bases = params[:bases]
    @bases.each do |key, value|
      @base = Base.new(value[:base])
      if not value[:layers].nil?
        value[:layers].each do |key, value|
          @layer = Layer.create!(value)
          @base.layers << @layer
        end
        @base.save!
      end
      @greenroof.bases << @base
    end


    if params[:plants].nil?
      #flash.now[:error] = "Et lisännyt yhtään kasvia."
      respond_to do |format|
        #format.js { render :action => 'new' }
      end
      return
    else
      params[:plants].each do |id|
        @plant = Plant.find_by_id(id)
        if not @plant.nil?
          @greenroof.plants << @plant
        end
      end
    end

    if @greenroof.save!
      flash[:success] = "Viherkaton lisäys onnistui!"
      respond_to do |format|
        format.json { render :json => {id: @greenroof.id} }
      end

    else
      if not params[:plants].nil? and not params[:environment][:id].empty?
        respond_to do |format|
          #format.js { render :action => 'new' }
        end
      end
    end
  end

  def index
    respond_to do |format|
      #@greenroofs = Greenroof.paginate(page: params[:page])
      #@greenroofs = Greenroof.all


      @count = 0
      if params[:page].present?
        @greenroofs = Greenroof.paginate(page: params[:page], per_page: params[:per_page])
        @count = @greenroofs.total_entries
      else
        @greenroofs = Greenroof.all
        @count = @greenroofs.length
      end

      format.html { render :html => @greenroofs } # index.html.erb

      @jsonGreenroofs = []


      # TÄMÄ FUNKTIO TURHA KUN VIHERKATOLLA ON OMISTAJA KENTTÄ
      @greenroofs.each do |groof|
        @user = User.find_by_id(groof.user_id)
        hash = groof.attributes
        hash[:thumb] = groof.images.first.thumb unless groof.images.first.nil?
        if (signed_in?)
          hash[:creator] = (@user.id == current_user.id)
        else
          hash[:creator] = false
        end

        # TÄMÄ FUNKTIO YLIKIRJOITTAA OSAN AIKAISEMMASTA FUNKTIOSTA EIKÄ SE OLE TURHA :D
        hash[:user] = groof.owner.to_s

        @jsonGreenroofs << hash
      end

      @jsonUser = User.all

      #format.json { render :json => {count: @greenroofs.total_entries, greenroofs: @jsonGreenroofs} }
      format.json { render :json => {admin: admin?, count: @count, greenroofs: @jsonGreenroofs} }
    end
  end

  def destroy

    @greenroof = Greenroof.find(params[:id])
    respond_to do |format|
      @response = ""
      if (@greenroof.user_id == current_user.id) or current_user.admin?
        @greenroof.destroy
        @response = "success"
      else
        @response = "error"
      end

      format.json { render :json => {response: @response} }
    end
  end

  def upload
    redirect_to_groof_show = false
    @groof = Greenroof.find_by_id(params[:id])
    return unless @groof.user.id == current_user.id
    unless params["file-0"].nil?

        # The path to the directory for the photos of the created greenroof.
        directory = "/public/greenroofs/photos/" + params[:id]

        # If the directory does not exists a new one will be created.
        FileUtils.mkdir_p Dir.pwd + directory if not File.directory? Dir.pwd + directory

        # The filename for the new photo.
        if not (@groof.images.first.nil?)
          photoFilename = @groof.images.first.photo
          redirect_to_groof_show = true
        else
          photoFilename = params[:id] + "_" + Time.now.to_i.to_s + "_" + Digest::MD5.hexdigest(params["file-0"].original_filename)
        end
        # The full path for the photo.
        photoPath = Dir.pwd + directory + "/" + photoFilename

        file = File.read(params["file-0"].tempfile) if params["file-0"]
        f = File.new(photoPath, "w+")
        f.write file
        f.close

        # Filename for the thumbnail
        if not (@groof.images.first.nil?)
          thumbFilename = @groof.images.first.thumb
        else
          thumbFilename = params[:id] + "_thumb_" + Time.now.to_i.to_s + "_" + Digest::MD5.hexdigest(params["file-0"].original_filename)
        end
        thumb = Magick::Image.read(photoPath).first
        thumb.crop_resized!(120, 120, Magick::NorthGravity)
        thumbPath = Dir.pwd + directory + "/" + thumbFilename
        thumb.write(thumbPath)

        # photo = "/photos/" + params[:id]

        img = Image.new(photo: photoFilename, thumb: thumbFilename)
        @groof.images.clear
        @groof.images << img
    end
      if @groof.save!
        flash[:success] = "Viherkaton lisäys onnistui!"

          render :js => "window.location = '/greenroofs/" << @groof.id.to_s << "'"

      end


  end


    def edit
      @greenroof = Greenroof.find(params[:id])
      @roof = @greenroof.roof
      respond_to do |format|
        format.json { render :json => {plants: @greenroof.plants} }
        format.html { render :html => @greenroof } # index.html.erb
      end
    end


    def update
      @greenroof = Greenroof.find(params[:id])
      @greenroof.role = Role.where("value like ?", params[:role][:value]).first
      @greenroof.update_attributes(params[:greenroof])
      @roof = @greenroof.roof


      if not params[:purpose].nil?
        @greenroof.purposes.clear
        params[:purpose].each do |purp|
          purp[1].each do |toAddPurp|
            @purp = Purpose.find(toAddPurp)
            if (@purp != nil)
              @greenroof.purposes << @purp
            end
          end
        end


        if not params[:environment].nil?
          @roof.environments.clear
          params[:environment][:id].each do |env|
            @env = Environment.find_by_id(env)
            if (@env != nil)
              @roof.environments << @env
            end
          end
        else
          flash.now[:error] = "Et valinnut ympäristöä."
          respond_to do |format|
            #format.js { render :action => 'new' }
          end
          return
        end


        if not params[:customPlants].nil?
          @greenroof.custom_plants.clear
          params[:customPlants].each do |cplant|
            cplant[1].each do |toAddPlant|
              @cplant = CustomPlant.new(name: toAddPlant)
              @greenroof.custom_plants << @cplant
            end
          end
        end

        @greenroof.roof.update_attributes(params[:roof])
        @greenroof.roof.save

        @greenroof.bases.clear
        @bases = params[:bases]
        if !@bases.nil?
          @bases.each do |key, value|
            @base = Base.new(value[:base])
            if not value[:layers].nil?
              value[:layers].each do |key, value|
                @layer = Layer.new(value)
                @base.layers << @layer
              end
            end
            @greenroof.bases << @base
          end
        end


        @greenroof.plants.clear
        params[:plants].each do |id|
          @plant = Plant.find_by_id(id)
          if not @plant.nil? && @greenroof.plants.find(@plant)
            @greenroof.plants << @plant
          end
        end


        if @greenroof.save!
          flash[:success] = "Viherkaton muokkaaminen onnistui!"
          respond_to do |format|
            format.json { render :json => {id: @greenroof.id} }
          end

        else
          if not params[:plants].nil? and not params[:environment][:id].empty?
            respond_to do |format|
              #format.js { render :action => 'new' }
            end
          end
        end



      end
    end

    private

    def owner
      unless Greenroof.find_by_id(params[:id]).user_id == current_user.id
        redirect_to root_url
      end
    end
  end
