###############################################################################
# Coyotes hunt harbor seal pups on the California coast  ######################
# Code Author: Frankie Gerraty (frankiegerraty@gmail.com; fgerraty@ucsc.edu) ##
# Manuscript Authors: F. Gerraty, S. Grimes, S. Pemberton, S. Allen, S. Codde #
###############################################################################
#------------------------------------------------------------------------------

# Part 1: Load Packages -------------------------------------------------------

# Load packages
packages<- c("tidyverse", "janitor", "lubridate", "ggthemes")

pacman::p_load(packages, character.only = TRUE); rm(packages)


# Part 2: Import and Clean Data -----------------------------------------------

#Import predation observation metadata
predation_observations <- read_csv("data/HASE_Predation_Observations.csv") %>% 
  clean_names() %>% 
  #Clean date formatting
  mutate(date = ymd(observation_date),
         day = yday(date),
         year = year(date)) 
         
#Import systematic seal abundance monitoring data (2009-2018)
seal_counts_pre2018 <- read_csv("data/MacKerricher_HASE_Counts_Pre2018.csv") %>% 
  clean_names() %>% 
  #Clean date formatting
  mutate(date = mdy(date),
         day = yday(date),
         year = year(date)) %>% 
  #Drop oldest observations
  filter(year > 2010) %>% 
  #Remove irrelevant columns
  select(-duration, -time) %>% 
  #Replace NA values with zero for pups
  replace_na(list(pup = 0, adult = NA))

seal_counts_post2018 <- read_csv("data/MacKerricher_HASE_Counts_Post2018.csv") %>% 
  rename(adult = annual_adult_max,
         pup = annual_pup_max) %>% 
  pivot_longer(c("adult", "pup"), names_to = "age", values_to = "max_count")
  

# Part 3: Summarize Data ------------------------------------------------------

#Summarize seal predation data
seal_predation_summary <- predation_observations %>% 
  filter(observation_location == "MacKerricher State Park, Mendocino County, CA") %>% 
  group_by(year) %>% 
  summarise(max_count = n()) %>% 
  mutate(age = "dead_pup")

#Summarize seal abundance data
seal_count_summary <- seal_counts_pre2018 %>% 
  #Count max number of adults and pups documented each year
  pivot_longer(c("adult", "pup"), names_to = "age", values_to = "count") %>% 
  group_by(year, age) %>% 
  summarise(max_count = max(count, na.rm = TRUE), .groups = "drop") %>% 
  bind_rows(., seal_counts_post2018, seal_predation_summary)
  
# Assess mean and standard error of coyote-killed harbor seal pup length 

#Mean = 80.57 cm
mean(predation_observations$length, na.rm = TRUE) 

#SE = 0.89
sd(predation_observations$length, na.rm = TRUE)/sqrt(length(na.omit(predation_observations$length)))


# PART 4: Generate Figures ----------------------------------------------------

# Count Plot ####

ggplot(seal_count_summary, 
       aes(x=year, y=max_count, 
           fill = factor(age, 
                         levels = c("dead_pup", "pup", "adult"))))+
  #Stacked bar chart
  geom_bar(stat = "identity", position="stack")+
  theme_few()+
  labs(y = "Maximum # Individuals Documented Per Year", 
       x="Year", fill = "Age Class")+
  scale_fill_manual(values = c("red", "#22A884FF","#440154FF"), labels = c("Coyote-\nKilled Pup", "Pup", "Adult"))+
  theme(legend.position = c(0.9, 0.83),
        legend.box.background = element_rect(colour = "black", linewidth = 1),
        panel.border = element_rect(colour = "black", linewidth = 1))



ggplot((seal_count_summary %>% 
          filter(age != "adult")), #filter adults to just show pups
       aes(x=year, y=max_count, 
           fill = factor(age, 
                         levels = c("dead_pup", "pup"))))+
  #Stacked bar chart
  geom_bar(stat = "identity", position="stack")+
  theme_few()+
  labs(y = "Maximum # Individuals Documented Per Year", 
       x="Year", fill = "Category")+
  scale_fill_manual(values = c("red", "#6497bf"), labels = c("Coyote-\nKilled Pup", "Pup (Alive)"))+
  theme(legend.position = c(0.901, 0.868),
        legend.box.background = element_rect(colour = "black", linewidth = 1),
        panel.border = element_rect(colour = "black", linewidth = 1))


ggsave("output/annual_summary.png", width = 7, height = 4.5, units = "in")


# Timing Plot ####

#Mendocino predation events timing summary

MC_predation_timing <- predation_observations %>% 
  filter(observation_location == "MacKerricher State Park, Mendocino County, CA") %>% 
  group_by(day) %>% 
  summarise(count = n())
  

ggplot(seal_counts_pre2018, aes(x=day, y=pup))+
  geom_point(alpha = .7, shape=16)+
  geom_vline(data = MC_predation_timing, 
             aes(xintercept = day, size=count), color = "red") +
  theme_few()+
  labs(y = "# Pups Observed (all years)", x="Day of Year", size = "# Coyote-Killed\nPups per Julian Day\n(sum of all years)")+
  geom_smooth(method = "gam", color = "black")+
  scale_size_continuous(range = c(.5,1.5), 
                        breaks= c(1,2,3,4),
                        labels = c(1,2,3,4))+
  guides(size=guide_legend(override.aes=list(colour="red")))+
  coord_cartesian(ylim = c(-2,50), xlim = c(92,165))+
  guides(size = guide_legend(nrow=1,
                             label.position = "top"))+
  theme(legend.position = c(0.86, 0.83),
        legend.box.background = element_rect(colour = "black", linewidth = 1),
        panel.border = element_rect(colour = "black", linewidth = 1))


ggsave("output/seasonality_plot.png", width = 7, height = 4.5, units = "in")
