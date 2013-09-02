class MicropostsController < ApplicationController
	before_filter :signed_in_user # This method defined in SessionsHelper
	before_filter :correct_user, only: :destroy

	def create
		@micropost = current_user.microposts.build(micropost_params)
		if @micropost.save
			flash[:success] = "Micrpost created!"
			redirect_to root_url
		else
			# Homepage expects a @feed_items instance variable...
			# so a failed submission would result in breaking the app.  
			# set @feed_item to an empty array to keep from breaking
			# and supressing the feed entirely (as shown in tutorial)
			@feed_items = [] 
			render 'static_pages/home'
		end
	end

	def destroy
		@micropost.destroy
		redirect_to root_url
	end

	private

		def micropost_params
			params.require(:micropost).permit(:content)
		end

		def correct_user
			@micropost = current_user.microposts.find_by_id(params[:id])
			redirect_to root_url if @micropost.nil?
		end

end
