#!/usr/bin/ruby
require 'big_stash/stash_operator'
require 'big_keeper/util/logger'
require 'big_keeper/util/pod_operator'
require 'big_keeper/util/xcode_operator'

module BigKeeper
  def self.switch_to(path, version, user, name, type)
    begin
      # Parse Bigkeeper file
      BigkeeperParser.parse("#{path}/Bigkeeper")

      version = BigkeeperParser.version if version == 'Version in Bigkeeper file'
      full_name = "#{version}_#{user}_#{name}"
      branch_name = "#{GitflowType.name(type)}/#{full_name}"

      GitService.new.verify_home_branch(path, branch_name, OperateType::SWITCH)

      stash_modules = PodfileOperator.new.modules_with_type("#{path}/Podfile",
                                BigkeeperParser.module_names, ModuleType::PATH)

      # Stash current branch
      StashService.new.stash_all(path, branch_name, user, stash_modules)

      # Switch to new feature
      GitOperator.new.checkout(path, branch_name)
      GitOperator.new.pull(path)

      # Apply home stash
      StashService.new.pop_stash(path, branch_name, 'Home')

      modules = PodfileOperator.new.modules_with_type("#{path}/Podfile",
                                BigkeeperParser.module_names, ModuleType::PATH)

      modules.each do |module_name|
        ModuleService.new.switch_to(path, user, module_name, branch_name, type)
      end

      # pod install
      PodOperator.pod_install(path, false)

      # Open home workspace
      XcodeOperator.open_workspace(path)
    ensure
    end
  end
end
