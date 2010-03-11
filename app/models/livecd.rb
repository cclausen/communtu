# each liveCD is stored in the database as an object of class Livecd
# this allows for better error logging and recovery
# note that the iso itself is stored in the file system, however

class Livecd < ActiveRecord::Base
  belongs_to :distribution
  belongs_to :derivative
  belongs_to :architecture
  belongs_to :user
  belongs_to :metapackage
  validates_presence_of :name, :distribution, :derivative, :architecture, :user

  # full version of liveCD, made from derivative, distribution and architecture
  def fullversion
    self.derivative.name.downcase+"-"+self.distribution.name.gsub(/[a-zA-Z ]/,'')+"-desktop-"+self.architecture.name
  end

  # unique name of liveCD
  def fullname
    "#{self.name}-#{self.fullversion}"
  end

  # filename of LiveCD in the file system
  def filename
    "#{RAILS_ROOT}/public/debs/#{self.fullname}.iso"
  end

  # url of LiveCD on the communtu server
  def url
    baseurl = if RAILS_ROOT.index("test").nil? then "http://communtu.org" else "http://test.communtu.de" end
    return "#{baseurl}/debs/#{self.fullname}.iso"
  end

  # check if a user supplied name is acceptable
  def self.check_name(name)
    if name.match(/^communtu-.*/)
      return I18n.t(:livecd_communtu_name)
    end
    if name.match(/^[A-Za-z0-9_-]*$/).nil?
      return I18n.t(:livecd_incorrect_name)
    end
    if !Livecd.find_by_name(name).nil?
      return I18n.t(:livecd_existing_name)
    end
    return nil
  end

  def worker
    MiddleMan.new_worker(:class => :livecd_worker,
                     :args => self.id,
                     :job_key => :livecd_worker,
                     :singleton => true)
  end
  
  # create the liveCD in a forked process
  def fork_remaster
      self.pid = fork do
	 	        system 'echo "Livecd.find('+self.id.to_s+').remaster" | nohup script/console production'
      end
      self.save
  end

  # created liveCD, using script/remaster
  def remaster
    ver = self.fullversion
    iso = self.filename
    isourl = self.url
    fullname = self.fullname
    if !Dir.glob(iso)[0].nil? then
      # iso already exists? then we are done
      self.failed = false
    else
      # need to generate iso, use lock in order to prevent parallel generation of multiple isos
      system "dotlockfile -r 1000 #{RAILS_ROOT}/livecd_lock"
      begin
        self.generating = true
        self.save
        # log to log/livecd.log
        call = "(echo; echo \"------------------------------------\"; echo \"Creating live CD #{fullname}\"; date) >> #{RAILS_ROOT}/log/"
        system (call+"livecd.log")
        system (call+"livecd.short.log")
        # Karmic and higher need virtualisation due to requirement of sqaushfs version >= 4 (on the server, we have Hardy)
        if self.distribution_id >= 5 then
          virt = "-v "
        else
          virt = ""
        end
        remaster_call = "#{RAILS_ROOT}/script/remaster create #{virt}#{ver} #{iso} #{self.name} #{self.srcdeb} #{self.installdeb} >> #{RAILS_ROOT}/log/livecd.log 2>&1"
        system "echo \"#{remaster_call}\" >> #{RAILS_ROOT}/log/livecd.log"
        self.failed = !(system remaster_call)
        # kill VM, necessary in case of abrupt exit
        system "pkill -f \"kvm -daemonize .* -redir tcp:2222::22\""
        system "sudo kill-kvm 2222"
        call = "(echo; echo \"finished at:\"; date; echo; echo) >> #{RAILS_ROOT}/log/"
        system (call+"livecd.log")
        system (call+"livecd.short.log")
        msg = if self.failed then "failed" else "succeeded" end
        call = "(echo; echo \"Creation of livd CD #{msg}\"; echo) >> #{RAILS_ROOT}/log/"
        system (call+"livecd.log")
        system (call+"livecd.short.log")
        if self.failed then
          self.log = IO.popen("tail -n80 #{RAILS_ROOT}/log/livecd.log").read
        end
      rescue
        self.log = "ruby code for live CD/DVD creation crashed"
        self.failed = true
      end
      system "dotlockfile -u #{RAILS_ROOT}/livecd_lock"
    end
    # store size and inform user via email
    if !self.failed then
      self.generated = true
      self.size = File.size(self.filename)
      MyMailer.deliver_livecd(self.user,isourl)
    else
      MyMailer.deliver_livecd_failed(self.user,self.fullname)
    end
    self.generating = false
    self.save
  end

  protected

  # cleanup of processes and iso files
  def before_destroy
    begin
      # if process for creating the livecd is waiting but has not started yet, kill it
      if !self.generated and !self.generating and !self.pid.nil?
        Process.kill("TERM", self.pid)
        # use time for deletion of iso as waiting time
        File.delete self.filename
        Process.kill("KILL", self.pid)
      else
        # only delete the iso
        fork do File.delete self.filename end
      end
    rescue
    end
  end
end
