# Shocks: The Coronavirus Pandemic

## October 24, 2020

<br>

### Background

As previously discussed, the Coronavirus Pandemic has affected many different facets which will in some way change the outcome of the 2020 Presidential Election. First and foremost, the pandemic makes in-person voting dangerous. As a result, many states have strengthened and expanded mail-in voting. [The New York Times](https://www.nytimes.com/2020/10/11/us/elections/vote-by-mail-election.html?auth=login-google) predicts that the 2020 election may end up much like the 2000 election, ending with a Supreme Court case as a result of possible lawsuits cause by the rejection of ballots filled out incorrectly.

As we have discussed in previous posts, economic data is a difficult predictor to use in this election because of the drastic effects of the pandemic. [The Wall Street Journal](https://www.wsj.com/articles/its-the-economy-stupid-carries-less-weight-in-2020-election-11599989400) shares this view, saying that the econmy does not carry as much weight during this electoin cycle, due to both increasing polarization, which skews people's perceptions of the economy, and the pandemic.

In this blog, I want to explore how the Coronavirus Pandemic will affect the 2020 Election Results. Because of this, most if not all of this blog will be dedicated to descriptive analysis rather than predictive analysis of the actual election results.

Polling is arguably the predictor which most reflects the opinions of the people, as it comes directly from the people themselves. Because polling reflects people's opinions, I will use Presidential Election polling averages from [FiveThirtyEight](https://data.fivethirtyeight.com) as my response variable, since it seems like a good proxy for public opinion. (An argument could also be made for using Presidential Approval, but because the Presidential Election polling is used most often in predictions). For this reason, I look at how the number of total Coronavirus Cases relates to Polling Averages.

### Theory

***The working theory for this blog is that as Coronavirus Cases increase, less people will vote for Trump, because they will blame him for inadequately responding to the pandemic.***

### Methods

***I created logistic regression models from CDC Coronavirus data and FiveThirtyEight Polling Averages.***

## Data 

I used Coronavirus state-level data from the [CDC](https://data.cdc.gov/Case-Surveillance/United-States-COVID-19-Cases-and-Deaths-by-State-o/9mfq-cb36) and [FiveThirtyEight](https://data.fivethirtyeight.com) state polling averages. Particularly, I used the number of Total Coronavirus Cases in each state (CDC) and Polling Average (Trend Adjusted), which is an average of polls for a specified time period, adjusted by FiveThirtyEight for changing trends in the data.

## Logistic Regression 

***We should use a train-test split and make sure to check test accuracy.***

Because our data was split into observations by candidate (i.e. for each poll there were actually two observations, one for Trump and one for Biden), I decided to fit two different regression models. I decided to

I did this for two reasons:
* I did not like how the 2 party vote share made it seem like 100% of people voted for either Trump or Biden. I thought it would be interesting to see if there were any trends relating to people refusing to vote for either candidate depending on Coronavirus Cases. (i.e. I wondered if people would be less inclined to vote for either major candidate because they lose faith in the parties to solve the pandemic issue.)
* I did not want to inflate numbers for either candidate. By changing a raw vote share to a two-party vote share, it may make it seem like a candidate has a bigger lead, when they really don't.

Also, because we know that states differ greatly in their political leanings, I thought it was important to create an interaction term for state. This was so that we could see trends within states, rather than across states.

However, because there are not a lot of polling averages for each state, we need to be really careful about overfitting the data. So, we should make sure that we create a train-test split of the data. I chose to do a 75-25 split at random. In addition, because there are so many interaction terms of total_cases and states, it is difficult to write out a logistic regression equation (there are ~40+ variables!). Instead, we can write out the code which produces the model for each candidate: 

```
glm(polling_average ~ total_cases * state, family = "quasibinomial")
```

We use quasibinomial here because our polling averages are not discrete values of 0 and 1 (failure and success), as a normal binomial logit would expect, but instead range from 0 to 1. 

After training the data on the 75% training set, we can then test the data on our 25% testing set. To determine the accuracy of the test, we can calculate the RMSE (Root Mean Squared Error -- which means about how far off each prediction is from the actual value, on average).

```
RMSE = sqrt(mean((actual - predicted)^2))
```

For Trump's model, the training RMSE was 0.001689, or about 0.1689%, and the testing RMSE was 0.002877, or about 0.2877%. For Biden's model, the training RMSE was 0.001798, or about 0.1798%, and the testing RMSE was 0.002877, or about 0.2877%. Even on the testing set, the RMSE is low. 0.2877% is very small, and elections are unlikely to be within that margin of error (though, still possible!). This tells us that our model is pretty accurate for predicting the polling averages.

### Results

***While the model RMSE is extremely low, this is likely due to low variance in the data, rather than predictive power.***

## Accuracy

We can look at a graph of predicted vs. actual values to also see the results and accuracy of the regression:

![Model Accuracy](../figures/Shocks_Model_Accuracy.png)

However, this does seem suspicious, given that some of the interaction terms indicate that some states actually respond more positively towards Trump the higher that their Total Cases increases, which is contrary to our theory.

## Battleground State Investigations

We can investigate some states to see these relationships. Because we are particularly interested in Battleground states, it would be cool to look at Arizona, Michigan, and Ohio in particular.

![Arizona Model](../figures/Shocks_Model_Accuracy.png)

![Michigan Model](../figures/Shocks_Model_Accuracy.png)

![Ohio Model](../figures/Shocks_Model_Accuracy.png)
