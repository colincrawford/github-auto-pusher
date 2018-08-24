require 'logger'

class GithubAutoPusher
  VERSION = "0.1.0" 

  ###
  # default options for IoC (dependency injection)
  ###
  DEFAULT_UPDATE_INTERVAL = 60 * 30
  DEFAULT_COMMIT_MESSAGE = "scheduled auto commit"
  DEFAULT_WAIT = Proc.new { |ms| sleep ms }
  # run forever by default
  DEFAULT_FINISHED_LOOPING = Proc.new { |num_loops| false }

  def initialize(
    filesystem: Dir,
    interval: DEFAULT_UPDATE_INTERVAL,
    wait: DEFAULT_WAIT,
    finished_looping: DEFAULT_FINISHED_LOOPING,
    logger: Logger.new(STDOUT) 
  )
    @interval = interval
    @filesystem = filesystem
    @wait = wait 
    @finished_looping = finished_looping
    @logger = logger
  end

  def start
    if in_git_repo?
      @logger.run("running on branch #{git_current_branch}")
      run_loop
    else
      @logger.error("You're not in a git repo!")
    end
  end

  def run_loop
    num_loops = 0
    until @finished_looping.call(num_loops)
      @wait.call(@interval)
      update_repo_with_log
      num_loops += 1
    end
  end

  def update_repo_with_log
    update_repo
    log_repo_update
  end

  def log_repo_update 
    @logger.info("updated current branch: #{git_current_branch}")
  end

  def update_repo
    git_add
    git_commit
    git_push
  end

  def in_git_repo?
    @filesystem.entries(".").any? { |x| x == ".git"}
  end

  private
  def git_add
    `git add .`
  end

  def git_commit
    `git commit -m "#{DEFAULT_COMMIT_MESSAGE}"`
  end

  def git_push
    `git push`
  end

  def git_current_branch
    `git rev-parse --abbrev-ref HEAD --`
  end
end
