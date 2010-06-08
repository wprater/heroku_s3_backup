class HerokuS3Backup
  def self.backup
    begin
      require 'right_aws'
      
      bucket = if ENV['backup_bucket']
        ENV['backup_bucket']
      else
        "#{ENV['APP_NAME']}-heroku-backups"
      end

      puts "[#{Time.now}] heroku:backup started"
      name = "#{ENV['APP_NAME']}-#{Time.now.strftime('%Y-%m-%d-%H%M%S')}.dump"
      db = ENV['DATABASE_URL'].match(/postgres:\/\/([^:]+):([^@]+)@([^\/]+)\/(.+)/)
      system "PGPASSWORD=#{db[2]} pg_dump -Fc -i --username=#{db[1]} --host=#{db[3]} #{db[4]} > tmp/#{name}"
      
      s3 = RightAws::S3.new(ENV['s3_access_key_id'], ENV['s3_secret_access_key'])
      bucket = s3.bucket(bucket, true, 'private')
      
      bucket.put("backups/" + name, open("tmp/#{name}"))
      system "rm tmp/#{name}"
      puts "[#{Time.now}] heroku:backup complete"
      # rescue Exception => e
      #   require 'toadhopper'
      #   Toadhopper(ENV['hoptoad_key']).post!(e)
    end
  end
end
