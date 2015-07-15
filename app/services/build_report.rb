class BuildReport
  MAX_COMMENTS = ENV.fetch("MAX_COMMENTS").to_i

  def self.run(pull_request:, build:, token:)
    new(pull_request: pull_request, build: build, token: token).run
  end

  def initialize(pull_request:, build:, token:)
    @build = build
    @pull_request = pull_request
    @token = token
  end

  def run
    if build.completed?
      Commenter.new(pull_request).comment_on_violations(priority_violations)
      commit_status.set_success(build.violation_count)
      track_subscribed_build_completed
    end
  end

  private

  attr_reader :build, :token, :pull_request

  def priority_violations
    build.violations.take(MAX_COMMENTS)
  end

  def track_subscribed_build_completed
    if build.repo.subscription
      user = build.repo.subscription.user
      analytics = Analytics.new(user)
      analytics.track_build_completed(build.repo)
    end
  end

  def commit_status
    CommitStatus.new(
      repo_name: build.repo_name,
      sha: build.commit_sha,
      token: token,
    )
  end
end
