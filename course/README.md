# The course: reinforcement learning from zero, taught by ten Tracers

David Silver's 2015 UCL course on reinforcement learning, one page per lecture. Each page goes through the lecture in
his order, with a time stamp for every stop that opens the video at that moment, and after each idea shows the same
idea on a strip of 48 squares beside a real drop in Overwatch, with what the bots did when it was run.

The lectures and slides are David Silver's. These pages are a re-explanation written from the full lectures; quotes are
short and marked. Every number about the island comes from the logs in `data/logs` through `analysis/`, and each page
says which comparisons were planned before the runs and which were not.

| Lecture | Page | Lecture video | Series episode |
|---|---|---|---|
| 1 | [Introduction to Reinforcement Learning](lecture-01.md) | [video](https://www.youtube.com/watch?v=2pWv7GOvuf0) | [outline](../series/episode-01.md) |
| 2 | [Markov Decision Processes](lecture-02.md) | [video](https://www.youtube.com/watch?v=lfHX2hHRMVQ) | [outline](../series/episode-02.md) |
| 3 | [Planning by Dynamic Programming](lecture-03.md) | [video](https://www.youtube.com/watch?v=Nd1-UUMVfz4) | [outline](../series/episode-03.md) |
| 4 | [Model-Free Prediction](lecture-04.md) | [video](https://www.youtube.com/watch?v=PnHCvfgC_ZA) | [outline](../series/episode-04.md) |
| 5 | [Model-Free Control](lecture-05.md) | [video](https://www.youtube.com/watch?v=0g4j2k_Ggc4) | [outline](../series/episode-05.md) |
| 6 | [Value Function Approximation](lecture-06.md) | [video](https://www.youtube.com/watch?v=UoPei5o4fps) | [outline](../series/episode-06.md) |
| 7 | [Policy Gradient](lecture-07.md) | [video](https://www.youtube.com/watch?v=KHZVXao4qXs) | [outline](../series/episode-07.md) |
| 8 | [Integrating Learning and Planning](lecture-08.md) | [video](https://www.youtube.com/watch?v=ItMutbeOHtc) | [outline](../series/episode-08.md) |
| 9 | [Exploration and Exploitation](lecture-09.md) | [video](https://www.youtube.com/watch?v=sGuiWX07sKw) | [outline](../series/episode-09.md) |

9 of 10 lectures are written so far.

The finale: [lesson 11, the wall she cannot see](lesson-11-partial-observability.md). Partial observability on the island, by simulation, and on a local language model.

How to use it: read one page, answer its "Guess first" questions before opening them, then come back a day later and
do the questions of an earlier lecture. Mixing lectures is harder than finishing one at a time and is remembered better.

The experiments themselves: [README](../README.md), [the night school build](../docs/night-school.md), and every measured number in one place: [the island fact sheet](island-fact-sheet.md).
