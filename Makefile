install:
	cp src/file_system_reporter.sh $(DESTDIR)/usr/bin/
	cp src/update_power_counter.sh $(DESTDIR)/usr/bin/
	cp src/99_smartmonster_sleep.d.sh $(DESTDIR)/etc/pm/sleep.d/
