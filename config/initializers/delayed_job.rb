# Delayed Job config
#
# Start background workers with:
# RAILS_ENV=production script/delayed_job -n 2 start

Delayed::Worker.destroy_failed_jobs = false
Delayed::Worker.sleep_delay = 2
Delayed::Worker.max_attempts = 1
#Delayed::Worker.delay_jobs = false