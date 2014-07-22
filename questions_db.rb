require 'singleton'
require 'sqlite3'

class DBObject
  attr_reader :id
  def initialize
    @id = nil
  end

  def save
    @id.nil? ? create : save
  end

  def table_name
  end

  protected
  attr_writer :id
  private
  def create
    vars = self.instance_variables[1..-1]
    params = vars.map { |var| instance_variable_get(var) }
    vars = vars.map { |var| var = var[1..-1] }
    marks = ('?, ' * (vars.length - 1)) + '?'
    str =
    <<-SQL
    INSERT INTO
      #{table_name} (#{vars.join(',')})
    VALUES
      (#{marks})
      SQL
    QuestionsDatabase.instance.execute(str, *params)
    @id = QuestionsDatabase.instance.last_insert_row_id
  end

  def update
    vars = self.instance_variables[1..-1]
    params = vars.map { |var| instance_variable_get(var) }
    params << @id
    vars = vars.map { |var| var = var[1..-1] }
    str = <<-SQL
    UPDATE
      #{table_name}
    SET
    SQL
    vars.each do |var|
      str << "#{var}= ? ,"
    end
    str = str[0..-2]
    str += <<-SQL
    WHERE
      id = ?;
    SQL
    puts str
    QuestionsDatabase.instance.execute(str, *params)
  end
end

class QuestionsDatabase < SQLite3::Database

  include Singleton

  def initialize

    super('questions.db')

    self.results_as_hash = true
    self.type_translation = true
  end
end

class User < DBObject
  def self.all
    results = QuestionsDatabase.instance.execute('SELECT * FROM users')
    results.map { |result| User.new(result) }
  end

  attr_accessor :id, :fname, :lname

  def initialize(options = {})
    @id, @fname, @lname = options.values_at('id', 'fname', 'lname')
  end

  def self.find_by_id(id)
    results = QuestionsDatabase.instance.execute(<<-SQL, id)
    SELECT
      *
    FROM
      users
    WHERE
      users.id =  ?
    SQL

    results.map { |result| User.new(result) }.first
  end

  def self.find_by_name(fname, lname)
    results = QuestionsDatabase.instance.execute(<<-SQL, *[fname, lname])
    SELECT
      *
    FROM
      users
    WHERE
      users.fname =  ?
      AND users.lname = ?
    SQL

    results.map { |result| User.new(result) }.first
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

  def liked_questions
    QuestionLike.liked_questions_for_user_id(@id)
  end

  def average_karma
    results = QuestionsDatabase.instance.execute(<<-SQL, @id)
    SELECT CAST(COUNT(user_id) AS FLOAT)/COUNT(DISTINCT(question_id)) AS karma
    FROM questions LEFT OUTER JOIN question_likes ON id = question_id
    WHERE author_id = ?
    SQL

    results.first['karma']
  end

  def table_name
    'users'
  end

  def save
    @id.nil? ? create : update
  end

  private
  # def create
#     params = [@fname, @lname]
#     QuestionsDatabase.instance.execute(<<-SQL, *params)
#     INSERT INTO
#       users (fname, lname)
#     VALUES
#       (?, ?)
#     SQL
#     @id = QuestionsDatabase.instance.last_insert_row_id
#   end
#
#   def update
#     params = [@fname, @lname, @id]
#     QuestionsDatabase.instance.execute(<<-SQL, *params)
#     UPDATE
#       users
#     SET
#       fname = ?
#       lname = ?
#     WHERE
#       id = ?
#     SQL
#   end
end

class Question < DBObject
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
    results = QuestionsDatabase.instance.execute(<<-SQL, id)
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
    results = QuestionsDatabase.instance.execute(<<-SQL, author_id)
    SELECT
      *
    FROM
      questions
    WHERE
      questions.author_id =  ?
    SQL

    results.map { |result| Question.new(result) }
  end

  def self.most_followed(n)
    QuestionFollower.most_followed_questions(n)
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

  def likers
    QuestionLike.likers_for_question_id(@id)
  end

  def num_likes
    QuestionLike.num_likes_for_question_id(@id)
  end

  def self.most_liked(n)
    QuestionLike.most_liked_questions(n)
  end

  def table_name
    'questions'
  end

  def save
    @id.nil? ? create : update
  end

  private
  # def create
#     params = [@title, @body, @author_id]
#     QuestionsDatabase.instance.execute(<<-SQL, *params)
#     INSERT INTO
#       questions (title, body, author_id)
#     VALUES
#       (?, ?, ?)
#     SQL
#     @id = QuestionsDatabase.instance.last_insert_row_id
#   end
#
#   def update
#     params = [@title, @body, @author_id]
#     QuestionsDatabase.instance.execute(<<-SQL, *params)
#     UPDATE
#       questions
#     SET
#       title = ?
#       body = ?
#       author_id = ?
#     WHERE
#       id = ?
#     SQL
#   end
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
    results = QuestionsDatabase.instance.execute(<<-SQL, question_id)
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
    results = QuestionsDatabase.instance.execute(<<-SQL, user_id)
    SELECT
      question_id
    FROM
      question_followers
    WHERE
      question_followers.user_id =  ?
    SQL

    results.map { |result| Question.find_by_id(result['question_id']) }
  end

  def self.most_followed_questions(n)
    results= QuestionsDatabase.instance.execute(<<-SQL, n)
    SELECT
      question_id
    FROM
      (
      SELECT
        question_id, Count(user_id) AS num
      FROM
        question_followers
      GROUP BY question_id )
    ORDER BY
      num
    LIMIT
      ?
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

  def self.likers_for_question_id(question_id)
    results = QuestionsDatabase.instance.execute(<<-SQL, question_id)
    SELECT
      user_id
    FROM
      question_likes
    WHERE
      question_likes.question_id =  ?
    SQL

    results.map { |result| User.find_by_id(result['user_id']) }
  end

  def self.num_like_for_question_id(question_id)
    results = QuestionsDatabase.instance.execute(<<-SQL, question_id)
    SELECT
      Count(user_id) AS num
    FROM
      question_likes
    WHERE question_id = ?
    GROUP BY question_id
    SQL

    results.first['num']
  end

  def self.liked_questions_for_user_id(user_id)
    results = QuestionsDatabase.instance.execute(<<-SQL, user_id)
    SELECT
      question_id
    FROM
      question_likes
    WHERE user_id = ?
    SQL

    results.map { |result| Question.find_by_id(result['question_id']) }
  end


  def self.most_liked_questions(n)
    results= QuestionsDatabase.instance.execute(<<-SQL, n)
    SELECT
      question_id
    FROM
      (
      SELECT
        question_id, Count(user_id) AS num
      FROM
        question_likes
      GROUP BY question_id )
    ORDER BY
      num
    LIMIT
      ?
    SQL

    results.map { |result| Question.find_by_id(result['question_id']) }
  end
end

class Reply < DBObject
  def self.all
    results = QuestionsDatabase.instance.execute('SELECT * FROM replies')
    results.map { |result| Reply.new(result) }
  end

  attr_accessor :id, :question_id, :parent_reply, :author_id, :body

  def initialize(options = {})
    @id, @question_id, @parent_reply, @author_id, @body =
      options.values_at('id', 'question_id', 'parent_reply', 'author_id', 'body')
  end

  def self.find_by_id(id)
    results = QuestionsDatabase.instance.execute(<<-SQL, id)
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
    results = QuestionsDatabase.instance.execute(<<-SQL, question_id)
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
    results = QuestionsDatabase.instance.execute(<<-SQL, user_id)
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
    Question.find_by_id(@question_id)
  end

  def parent_reply
    Reply.find_by_id(@parent_reply)
  end

  def child_replies
    results = QuestionsDatabase.instance.execute(<<-SQL, @id)
    SELECT
      *
    FROM
      replies
    WHERE
      replies.parent_reply =  ?
    SQL

    results.map { |result| Reply.new(result) }
  end

  def table_name
    'replies'
  end

  def save
    @id.nil? ? create : update
  end

  private
  # def create
#     params = [@question_id, @parent_reply, @author_id, @body]
#     QuestionsDatabase.instance.execute(<<-SQL, *params)
#     INSERT INTO
#       replies (question_id, parent_reply, author_id, body)
#     VALUES
#       (?, ?, ?, ?)
#     SQL
#     @id = QuestionsDatabase.instance.last_insert_row_id
#   end
#
#   def update
#     params = [@qid, @parent, @author_id, @body]
#     QuestionsDatabase.instance.execute(<<-SQL, *params)
#     UPDATE
#       replies
#     SET
#       question_id = ?
#       parent_reply = ?
#       author_id = ?
#       body = ?
#     WHERE
#       id = ?
#     SQL
#   end
end