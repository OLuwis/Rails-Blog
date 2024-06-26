class PostsController < ApplicationController
  def index
    if params[:user_id]
      user = User.find(params[:user_id])
      @posts = user.posts.order(created_at: :desc).page params[:page]
    elsif params[:tag]
      tag = Tag.find(params[:tag])
      @posts = tag.posts.order(created_at: :desc).page params[:page]
    else
      @posts = Post.order(created_at: :desc).page params[:page]
    end
  end

  def show
    @post = Post.find(params[:id])
    @comments = @post.comments.order(created_at: :desc)
  end

  def new
    @post = current_user.posts.build
  end

  def create
    @post = current_user.posts.build(title: post_params[:title], body: post_params[:body])
    extract_tags(post_params[:tags]) if post_params[:tags]

    if @post.save
      redirect_to root_path, notice: I18n.t("controller.created", data: "Post")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @post = current_user.posts.find(params[:id])
  end

  def update
    @post = current_user.posts.find(params[:id])
    @post.tags.clear

    extract_tags(post_params[:tags]) if post_params[:tags]

    if @post.update(title: post_params[:title], body: post_params[:body])
      redirect_to post_path(@post), notice: I18n.t("controller.updated", data: "Post")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @post = current_user.posts.find(params[:id])
    @post.destroy

    redirect_to root_path, notice: I18n.t("controller.deleted", data: "Post")
  end

  def queue
    text = Text.new
    text.save
    text.file.attach(params[:text])

    if text.file.attached?
      PostsJob.perform_async(url_for(text.file), current_user.id)
      redirect_to root_path, notice: I18n.t("auto.message")
    else
      redirect_to auto_post_path, status: :unprocessable_entity
    end
  end

  private
    def extract_tags(tags)
      tags.split(/, |,/).each do |tag|
        @post.tags << Tag.find_or_create_by(name: tag.strip)
      end
    end

    def post_params
      params.require(:post).permit(:title, :body, :tags)
    end

end
