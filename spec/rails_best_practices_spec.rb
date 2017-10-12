require File.expand_path("../spec_helper", __FILE__)

module Danger
  describe Danger::DangerRailsBestPractices do
    it "should be a plugin" do
      expect(Danger::DangerRailsBestPractices.new(nil)).to be_a Danger::Plugin
    end

    #
    # You should test your custom attributes and methods here
    #
    describe "with Dangerfile" do
      before do
        @dangerfile = testing_dangerfile
        @rails_best_practices = @dangerfile.rails_best_practices
      end

      it "can handle no changed files" do
        allow(@rails_best_practices.git).to receive(:modified_files).and_return([])
        allow(@rails_best_practices.git).to receive(:added_files).and_return([])

        @rails_best_practices.check

        expect(@rails_best_practices.violation_report[:warnings])
          .to be_empty
      end

      it "can pass command line options" do
        allow(@rails_best_practices.git).to receive(:modified_files).and_return([])
        allow(@rails_best_practices.git).to receive(:added_files).and_return(["app/models/user.rb"])
        allow(@rails_best_practices).to receive(:system)
          .with("bundle", "exec", "rails_best_practices", "--debug", "--format", "json", "--output-file", anything, "--only", "app/models/user\\.rb")
          .and_return(true)
        allow(File).to receive(:read).and_return('[{"filename":"' + File.join(Dir.pwd, "app/models/user.rb") + '","line_number":"2","message":"foo"}]')

        @rails_best_practices.check(command_opts: ["--debug"])
      end

      it "can comment rails_best_practices warning" do
        allow(@rails_best_practices.git).to receive(:modified_files).and_return(["app/controllers/users_controller.rb"])
        allow(@rails_best_practices.git).to receive(:added_files).and_return(["app/models/user.rb"])
        allow(@rails_best_practices).to receive(:system)
          .with("bundle", "exec", "rails_best_practices", "--format", "json", "--output-file", anything, "--only", "app/controllers/users_controller\\.rb,app/models/user\\.rb")
          .and_return(true)
        allow(File).to receive(:read).and_return('[{"filename":"' + File.join(Dir.pwd, "app/models/user.rb") + '","line_number":"2","message":"foo"}]')

        @rails_best_practices.check

        expect(@rails_best_practices.violation_report[:warnings].first.to_s)
          .to eq("Violation foo { sticky: false, file: app/models/user.rb, line: 2 }")
      end
    end
  end
end
