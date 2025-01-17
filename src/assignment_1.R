library(tidyverse)
library(tidyr)
library(ggthemes)
library(lubridate)
library(ggp)

# Now that we have learned how to munge (manipulate) data
# and plot it, we will work on using these skills in new ways


####-----Reading in Data and Stacking it ----- ####
#Reading in files
files <- list.files('data',full.names=T)

#Read in individual data files
ndmi <- read_csv(files[1]) %>% 
  rename(burned=2,unburned=3) %>%
  mutate(data='ndmi')

ndsi <- read_csv(files[2]) %>% 
  rename(burned=2,unburned=3) %>%
  mutate(data='ndsi')

ndvi <- read_csv(files[3])%>% 
  rename(burned=2,unburned=3) %>%
  mutate(data='ndvi')

# Stack as a tidy dataset
full_long <- rbind(ndvi,ndmi,ndsi) %>% 
  gather(key='site',value='value',-DateTime,-data) %>%
  filter(!is.na(value))


##### Question 1 #####
#1 What is the correlation between NDVI and NDMI? - here I want you to
#convert the full_long dataset in to a wide dataset using the 
#function "spread" and then make a plot that shows the correlation as a
# function of if the site was burned or not

full_wide <- spread(data=full_long,key='data',value='value') %>%
  filter_if(is.numeric,all_vars(!is.na(.))) %>%
  mutate(month = month(DateTime),
         year = year(DateTime))

summer_only <- filter(full_wide,month %in% c(6,7,8,9))

ggplot(summer_only,aes(x=ndmi,y=ndvi,color=site)) + 
  geom_point() + 
  theme_few() + 
  scale_color_few() + 
  theme(legend.position=c(0.8,0.8))

# There is a positive correlation between moisture (NDMI) and vegetation (NDVI)
# in both the burned and unburned plots. A subtle increase in moisture leads to 
# a notable increase in vegetation. The unburned sites (obviously) have a
# higher vegetative cover on average.

#### Question 2 ####
#2) What is the correlation between average NDSI (normalized 
# snow index) for January - April and average NDVI for June-August?
#In other words, does the previous year's snow cover influence vegetation
# growth for the following summer? 

ggplot(full_wide, aes(x=ndsi, filter(month %in% c(1,2,3,4)), 
                      y=ndvi, filter(month %in% c(6,7,8))))+
  geom_point() +
  geom_smooth(method='lm') +
  theme_few() + 
  scale_color_few() + 
  theme(legend.position="bottom")

## Generate new winter dataset w/ averages ##

WinterNDSI= full_long %>%
  filter(!is.na(value)) %>%
  pivot_wider(names_from = c(data),
              values_from = c(value)) %>%
  mutate(year= year(DateTime),
         month= month(DateTime)) %>%
  filter(month %in% c(1,2,3,4)) %>%
  group_by(site, year) %>%
  summarise(MeanNDSI = mean(ndsi))

## Generate ndvi summer dataset w/ averages ##

SummerNDVI= full_long %>%
  filter(!is.na(value)) %>%
  pivot_wider(names_from = c(data),
values_from = c(value)) %>%
  mutate(year= year(DateTime),
         month= month(DateTime)) %>%
  filter(month %in% c(6,7,8)) %>%
  group_by(site, year) %>%
  summarise(MeanNDVI = mean(ndvi))

## Combine datasets ##

Q2 = inner_join(WinterNDSI,
                SummerNDVI)

## Plotting Data ##

Q2 %>%
  filter_if(is.numeric,all_vars(!is.na(.))) %>%
ggplot(aes(x=MeanNDSI, y=MeanNDVI))+
  geom_point()+
  geom_smooth(method="lm")
  

## End code for question 2 -----------------

#After taking averages and fitting to a linear
#model, it appears that there is a slightly positive correlation.

###### Question 3 ####
#How is the snow effect from question 2 different between pre- and post-burn
# and burned and unburned? 

## Attempting with updated dataset ##

## Creating Pre & Post-burn datasets ##

Q3Pre= Q2 %>%
  filter(year %in% c(1984:2002))

Q3Post= Q2 %>%
  filter(year %in% c(2003:2019))

## Plotting Averages ##

ggplot(data=Q3Pre, aes(x=MeanNDSI, y=MeanNDVI, color=site))+
  geom_point() +
  geom_smooth(method="lm") +
  theme_few() + 
  scale_color_few() + 
  theme(legend.position="bottom")

ggplot(data=Q3Post, aes(x=MeanNDSI, y=MeanNDVI, color=site))+
  geom_point() +
  geom_smooth(method="lm") +
  theme_few() + 
  scale_color_few() + 
  theme(legend.position="bottom")

## Plotting with all values in initial dataset ##

full_wide %>% 
  filter(year %in% c(1984:2002)) %>%
ggplot(aes(x=ndsi, filter(month %in% c(1,2,3,4)), 
                      y=ndvi, filter(month %in% c(6,7,8)),
                      color= site))+
  geom_point() +
  geom_smooth() +
  theme_few() + 
  scale_color_few() + 
  theme(legend.position="bottom")


full_wide %>% 
  filter(year %in% c(2003:2019)) %>%
  ggplot(aes(x=ndsi, filter(month %in% c(1,2,3,4)), 
             y=ndvi, filter(month %in% c(6,7,8)),
             color= site))+
  geom_point() +
  geom_smooth() +
  theme_few() + 
  scale_color_few() + 
  theme(legend.position="bottom")


#The averages of the burned sites were driving the positive correlation prior to the burn occurring.
#After the burn, these sites began to show a negative correlation between snowfall and
#vegetative cover, while the unburned remained fairly unaffected. 
#When incorporating all values, he negative correlation between snowfall and vegetative 
#cover remains consistent in all sites, even following the burn. There is a strict differentiation between the 
#burned and unburned sites, but that is due to the difference in amount of NDVI.

###### Question 4 #####
#What month is the greenest month on average? Does this change in the burned
# plots after the fire? 

###Creating Individual datasets###

Q4= full_long %>%
  filter(!is.na(value)) %>%
  pivot_wider(names_from= c(data),
              values_from = c(value)) %>%
  mutate(year = year(DateTime),
         month = month(DateTime, label=T)) %>%
  group_by(month) %>%
  summarise(MeanNDVI=mean(ndvi, na.rm=T))

Q4Post= full_long %>%
  filter(!is.na(value)) %>%
  pivot_wider(names_from= c(data),
              values_from = c(value)) %>%
  mutate(year = year(DateTime),
         month = month(DateTime, label=T)) %>%
  filter(year %in% c(2003:2019)) %>%
  group_by(month, site) %>%
  summarise(MeanNDVI=mean(ndvi, na.rm=T)) %>%
  filter(site %in% c("burned"))

##Visualizing with barplots##

ggplot(data=Q4, aes(x=month, y=MeanNDVI)) +
  geom_col(fill= "lightblue",
           color="blue")+
  geom_col(data= Q4[Q4$month=="Aug",],
           aes(x=month, y=MeanNDVI),
           fill = "lightgreen",
           color = "green")+
  ylab("Mean NDVI")

ggplot(data=Q4Post, aes(x=month, y=MeanNDVI)) +
  geom_col(fill= "lightblue",
           color="blue")+
  geom_col(data= Q4Post[Q4Post$month=="Aug",],
           aes(x=month, y=MeanNDVI),
           fill = "lightgreen",
           color = "green")+
  ylab("Mean NDVI")


#August is the greenest month across all plots and remains so in burned plots
#Following the fire.

##### Question 5 ####
#What month is the snowiest on average?

##Creating average dataset##

Q5= full_long %>%
  filter(!is.na(value)) %>%
  pivot_wider(names_from= c(data),
              values_from = c(value)) %>%
  mutate(year = year(DateTime),
         month = month(DateTime, label=T)) %>%
  group_by(month) %>%
  summarise(MeanNDSI=mean(ndsi, na.rm=T))

##Plotting highest snowfall##

ggplot(data=Q5, aes(x=month, y=MeanNDSI)) +
  geom_col(fill= "lavender",
           color="red")+
  geom_col(data= Q5[Q5$month=="Jan",],
           aes(x=month, y=MeanNDSI),
           fill = "lightblue",
           color = "blue")+
  ylab("Mean NDSI")
