# Demo Script: KijaniKiosk Deployment Pipeline
## For Nia to read aloud during Monday's board meeting

---

[Amina opens two terminal windows side by side on the shared screen]

Good morning. What you are about to see is the system that protects our payments
service from bad software updates — automatically, without anyone having to intervene.

[Amina confirms both environments are running and healthy]

Right now, our payments service is running on the stable version — version 1.3. Running
alongside it, invisible to customers, is version 1.4, already deployed and waiting. Think
of it as a spare lane on a motorway, prepared and ready before any traffic enters it.

[Amina starts the monitoring script in the left terminal]

The monitoring system is now watching. It checks the health of our service every five
seconds. If anything goes wrong, it acts — no phone call, no delay, no one needs to
wake up in the middle of the night.

[Amina runs the traffic switch command in the right terminal]

We have just moved all customer traffic to version 1.4. Every payment request is now
being handled by the new version. The monitoring system is confirming it is healthy.

[Amina stops the version 1.4 service to simulate a critical fault]

Now we are introducing a fault — the kind of critical problem a new software version
might have in the real world. We are doing this deliberately so you can see what the
system does when something goes wrong.

[Both terminals show the monitoring system detecting failures]

Watch the left screen. The system has detected three consecutive failures. It has made
the decision to recover — without any human involvement, without anyone being called,
without anyone even being awake.

[Monitor confirms rollback complete and version 1.3 is serving]

Version 1.3 is serving again. The system detected the problem and restored normal
service in 18 seconds — faster than a human engineer could have responded.

[Amina displays the state files confirming the rollback]

The question for the board this morning was: can the system handle its own failures?
The answer is yes. In a real incident at this speed, our customers would not have
noticed. The payment service would have continued without interruption.

---

Word count (spoken sections only): 247 words
Rollback time sourced from: rollback-evidence.txt (T0: 06:14:55, T2: 06:15:13)
