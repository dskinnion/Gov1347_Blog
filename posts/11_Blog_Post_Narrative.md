# Media Narrative

## December 10, 2020

<br>

### Background

A post-election narrative is a story that is popularized by the media to explain some result of the election. For this blog, I will focus on the media narrative that COVID-19 actually helped Trump in this election.

Before the election, it was almost universally accepted that the effects of the pandemic would help Biden win the election. In this [UCLA Newsroom article](https://newsroom.ucla.edu/releases/covid-19-death-rates-election-voting) by Jessica Wolf, pre-election voter surveys indicated that there was a decline in support for the GOP from January to June in states with the highest rates of COVID-19 deaths. The article draws on a study by [Warsaw, Vavreck, and Baxter-King](https://advances.sciencemag.org/content/6/44/eabd8564/tab-pdf), and Vavreck asserted that such trends continued into mid-Septmeber. If the trends in this study were correct, and support for the GOP and Trump truly did decrease as COVID-19 ravaged on, then we would expect Trump's support in 2020 to be lower than it was in the 2016 election as well (Although, an argument could be made that this would not be a perfect comparison as Trump faces Biden as opposed to Clinton this year).

While Biden did indeed win the election, he did not win in the landslide that was predicted by most. How did the media account for this? Rather than causing the landslide for Biden that was expected, the effects of COVID-19 perhaps had the inverse effect. The story coming out after election night was that COVID-19 actually helped Trump. [NPR](https://www.npr.org/sections/health-shots/2020/11/06/930897912/many-places-hard-hit-by-covid-19-leaned-more-toward-trump-in-2020-than-2016) claims that those counties hit hardest by COVID-19 in terms of death rate actually leaned more towards Trump than they previously did. [AP News](https://apnews.com/article/counties-worst-virus-surges-voted-trump-d671a483534024b5486715da6edb6ebf) makes similar claims, and highlights the increasing disparity between COVID-19 perceptions between Biden and Trump voters: those that voted for Biden mostly see that pandemic as not under control at all, whereas those that voted for Trump mostly see the pandemic as at least somewhat under control.

### Testable Implications

The best way to test this narrative would be to look at support for Trump over time at the county level. As COVID-19 rates increased, we would expect support for Trump to decrease. This is what Warsaw et. al. attempted to do pre-election. However, if the results of the 2020 election have taught us one thing, it's that the polls (and likely the voter-surveys used by Warsaw et. al.) were wrong again. This election, they were worse than they were in 2016. Because of this, it does not seem like the most thorough way of testing this claim, especially considering that Trump consistently outperformed his polling numbers.

What we could do instead, would be to look at the difference in a county's vote in 2020 compared to in 2016. While this certainly isn't a perfect approach (again, Trump faces off againt different candidates), it may be the best we can do.

If the media narrative is correct that an increase in COVID-19 death rates actually led to more support for Trump, then we should notice that on the county level, those with higher rates of COVID-19 would vote in higher proportions for Trump in 2020 than they did in 2016.

### Some Important Caveats

The purpose of this blog is not to give a definitive answer to whether or not the media narrative is true. Instead, I will provide explanations and analysis as to whether or not the data initially support the media narrative. There are plenty of confounding variables that may affect the variables in question. For instance, increasing polarization may lead to red states becoming more Republican, and blue states becoming more Democratic. Increasing polarization may also lead to red states becoming hotspots for COVID-19 once mask-wearing became politicized, whereas blue states may recover more because of the same effect. I will attempt to look at this one confounding variable (albeit in a somewhat circular fashion due to a lack of current data), but note that there are many more. Again, the analysis provided here will not be determinative, but instead only exploratory.

Also, due to the wide range of values for COVID-19 related variables (eg. deaths, cases, and both rates), I have created new variables with the log of each. However, because many counties have not reported any deaths, the log variable was calculated as -Inf (since the log(0) is impossible), so I recoded these as 0 (even though that would technically indicate 1 death).



