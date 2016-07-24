class Admin::PageContentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_page_content, only: [:show, :edit, :update, :destroy]
  authorize_resource

  # GET /page_contents
  # GET /page_contents.json
  def index
    @page_contents = PageContent.all
  end

  # GET /page_contents/1
  # GET /page_contents/1.json
  def show
  end

  # GET /page_contents/new
  def new
    @page_content = PageContent.new
  end

  # GET /page_contents/1/edit
  def edit
  end

  # POST /page_contents
  # POST /page_contents.json
  def create
    @page_content = PageContent.new(page_content_params)

    respond_to do |format|
      if @page_content.save
        format.html { redirect_to [:admin,@page_content], notice: t('shared.msgs.success_created',
                            obj: t('activerecord.models.page_content', count: 1))}
      else
        format.html { render :new }
      end
    end
  end

  # PATCH/PUT /page_contents/1
  # PATCH/PUT /page_contents/1.json
  def update
    respond_to do |format|
      if @page_content.update(page_content_params)
        format.html { redirect_to [:admin,@page_content], notice: t('shared.msgs.success_updated',
                            obj: t('activerecord.models.page_content', count: 1))}
      else
        format.html { render :edit }
      end
    end
  end

  # DELETE /page_contents/1
  # DELETE /page_contents/1.json
  def destroy
    @page_content.destroy
    respond_to do |format|
      format.html { redirect_to admin_page_contents_url, notice: t('shared.msgs.success_destroyed',
                              obj: t('activerecord.models.page_content', count: 1))}
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_page_content
      @page_content = PageContent.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def page_content_params
      permitted = PageContent.globalize_attribute_names + [:name]
      params.require(:page_content).permit(*permitted)
    end
end
