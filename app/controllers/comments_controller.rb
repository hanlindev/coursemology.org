class CommentsController < ApplicationController
  load_and_authorize_resource :course

  before_filter :load_general_course_data, only: [:show, :index, :edit, :new, :view_for_question]

  def create
    @comment = Comment.new(params[:comment])
    @comment.user_course = curr_user_course
    authorize! :read, @comment.commentable
    if @comment.save
      commentable = @comment.commentable
      commentable.last_commented_at = @comment.created_at
      commentable.save

      CommentSubscription.populate_subscription(@comment)

      if curr_user_course.is_student?
        @comment.commentable.set_pending_comments(true)
      else
        @comment.commentable.set_pending_comments(false)
      end

      if @course.email_notify_enabled? PreferableItem.new_comment
        @comment.commentable.notify_user(curr_user_course, @comment, params[:origin])
      end

      respond_to do |format|
        #format.html { redirect_to params[:origin] }
        format.json {render json: @comment.commentable.comments_json}
      end
    end
  end

  def index
    if can? :see, :pending_comments
      @tab = params[:_tab]

      @all_topics = @course.commented_topics
      @pending_comments = @course.get_pending_comments
      @my_topics = curr_user_course.subscribed_topics
      @mine_pending_comments = @my_topics.select(&:pending?)

      case @tab
        when 'all'
          @topics = @all_topics
        when 'pending'
          @topics = @pending_comments
        when 'minepending'
          @topics = @mine_pending_comments
        when 'mine'
          @topics = @my_topics
        else
          @tab = 'pending'
          @topics = @pending_comments
      end
    else
      @topics = curr_user_course.subscribed_topics
    end

    @topics = sorting_and_paging(@topics)
  end

  def get_mystudent_pending_comments
    @topics = @course.get_pending_comments
    mystudents = curr_user_course.get_my_stds.map { |std| std.id }
    @topics = @topics.select { |ans| mystudents.include? ans.std_course_id }
  end

  def get_mystudent_comments
    @topics = @course.get_all_comments
    mystudents = curr_user_course.get_my_stds.map { |std| std.id }
    @topics = @topics.select { |ans| mystudents.include? ans.std_course_id }
  end

  def pending_toggle
    if !params[:cid] || !params[:ctype]
      return
    end
    pending_comment = PendingComments.find_by_answer_id_and_answer_type(params[:cid], params[:ctype])
    unless pending_comment
      pending_comment = PendingComments.create(answer_id:params[:cid], answer_type:params[:ctype],pending: false)
    end
    pending_comment.pending = !pending_comment.pending
    if pending_comment.save
      respond_to do |format|
        format.json {render json: {status: 'OK'}}
      end
    end
  end

  def view_for_question
    qn_type = params[:qn_type] || ''
    qn_id = params[:qn_id].to_i || 0
    @question = nil
    case
    when qn_type == 'Mcq'
      @question = Mcq.find(qn_id)
    when qn_type == 'CodingQuestion'
      @question = CodingQuestion.find(qn_id)
    end

    if !@question
      redirect_to course_url(@course)
      return
    end

    # verify subscription exist
    cs = CommentSubscription.where(
      user_course_id: curr_user_course.id,
      topic_id: @question.id,
      topic_type: @question.class).count
    if cs == 0
      redirect_to access_denied_path
      return
    end

    @asm = @question.asm_qns.first.asm
    @current_question = @question

  end

  private
  def sorting_and_paging(topics)
    @topics = topics.sort_by { |ans| ans.last_commented_at }.reverse
    @topics = Kaminari.paginate_array(@topics).page(params[:page]).per(10)
  end
end
