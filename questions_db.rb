require 'singleton'
require 'sqlite3'

class QuestionsDatabase < SQLite3::Database

  include Singleton

  def initialize

    super('questions.db')

    self.results_as_hash = true
    self.type_translation = true
  end
end

class User
  def self.all
    results = QuestionsDatabase.instance.execute('SELECT * FROM users')
    results.map { |result| User.new(result) }
  end

  attr_accessor :id, :fname, :lname

  def initialize(options = {})
    @id, @fname, @lname = options.values_at('id', 'fname', 'lname')
  end

  def self.find_by_id(id)
    results = SchoolDatabase.instance.execute(<<-SQL, id)
    SELECT
      *
    FROM
      users
    WHERE
      users.id =  ?
    SQL

    results.map { |result| User.new(result) }
  end

  def self.find_by_name(fname, lname)
    results = SchoolDatabase.instance.execute(<<-SQL, id)
    SELECT
      *
    FROM
      users
    WHERE
      users.fname =  ?
      AND users.lname = ?
    SQL

    results.map { |result| User.new(result) }
  end

  def authored_questions
    Question.find_by_author_id(@id)
  end

  def authored_replies
    Reply.find_by_user_id(@id)
  end

  def followed_questions
    QuestionFollower.followed_questions_for_user_id(@id)
  end

end

class Question
  def self.all
    results = QuestionsDatabase.instance.execute('SELECT * FROM questions')
    results.map { |result| Question.new(result) }
  end

  attr_accessor :id, :title, :body, :author_id

  def initialize(options = {})
    @id, @title, @body, @author_id =
      options.values_at('id', 'title', 'body', 'author_id')
  end

  def self.find_by_id(id)
    results = SchoolDatabase.instance.execute(<<-SQL, id)
    SELECT
      *
    FROM
      questions
    WHERE
      questions.id =  ?
    SQL

    results.map { |result| Question.new(result) }
  end

  def self.find_by_author_id(author_id)
    results = SchoolDatabase.instance.execute(<<-SQL, author_id)
    SELECT
      *
    FROM
      questions
    WHERE
      questions.author_id =  ?
    SQL

    results.map { |result| Question.new(result) }
  end

  def author
    User.find_by_id(@author_id)
  end

  def replies
    Reply.find_by_question_id(@id)
  end

  def followers
    QuestionFollower.followers_for_question_id(@id)
  end
end

class QuestionFollower
  def self.all
    results = QuestionsDatabase.instance.execute('SELECT * FROM question_followers')
    results.map { |result| QuestionFollower.new(result) }
  end

  attr_accessor :qid, :uid

  def initialize(options = {})
    @qid, @uid = options.values_at('question_id', 'user_id')
  end

  def self.followers_for_question_id(question_id)
    results = SchoolDatabase.instance.execute(<<-SQL, question_id)
    SELECT
      user_id
    FROM
      question_followers
    WHERE
      question_followers.question_id =  ?
    SQL

    results.map { |result| User.find_by_id(result['user_id']) }
  end

  def self.followed_questions_for_user_id(user_id)
    results = SchoolDatabase.instance.execute(<<-SQL, user_id)
    SELECT
      question_id
    FROM
      question_followers
    WHERE
      question_followers.user_id =  ?
    SQL

    results.map { |result| Question.find_by_id(result['question_id']) }
  end


end

class QuestionLike
  def self.all
    results = QuestionsDatabase.instance.execute('SELECT * FROM question_likes')
    results.map { |result| QuestionLike.new(result) }
  end

  attr_accessor :uid, :qid

  def initialize(options = {})
    @uid, @qid = options.values_at('user_id', 'question_id')
  end

end

class Reply
  def self.all
    results = QuestionsDatabase.instance.execute('SELECT * FROM replies')
    results.map { |result| Reply.new(result) }
  end

  attr_accessor :id, :qid, :parent, :author_id, :body

  def initialize(options = {})
    @id, @qid, @parent, @author_id, @body =
      options.values_at('id', 'question_id', 'parent_reply', 'author_id', 'body')
  end

  def self.find_by_id(id)
    results = SchoolDatabase.instance.execute(<<-SQL, id)
    SELECT
      *
    FROM
      replies
    WHERE
      replies.id =  ?
    SQL

    results.map { |result| Reply.new(result) }
  end

  def self.find_by_question_id(question_id)
    results = SchoolDatabase.instance.execute(<<-SQL, question_id)
    SELECT
      *
    FROM
      replies
    WHERE
      replies.question_id =  ?
    SQL

    results.map { |result| Reply.new(result) }
  end

  def self.find_by_user_id(user_id)
    results = SchoolDatabase.instance.execute(<<-SQL, user_id)
    SELECT
      *
    FROM
      replies
    WHERE
      replies.author_id =  ?
    SQL

    results.map { |result| Reply.new(result) }
  end

  def author
    User.find_by_id(@author_id)
  end

  def question
    Question.find_by_id(@qid)
  end

  def parent_reply
    Reply.find_by_id(@parent)
  end

  def child_replies
    results = SchoolDatabase.instance.execute(<<-SQL, @id)
    SELECT
      *
    FROM
      replies
    WHERE
      replies.parent_reply =  ?
    SQL

    results.map { |result| Reply.new(result) }
  end
end