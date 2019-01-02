install.packages("randomForest")
install.packages("caret")
install.packages("dummies")
install.packages("xgboost")
install.packages("plyr")
library(randomForest)
library(dummies)
library(xgboost)
library(dplyr)
library(rlang)
#Load Dataset
sal_df <- read.csv("C:\\Users\\40595\\Downloads\\WA_Sales_Products_2012-14.csv")
scheme_names <- read.csv("C:\\Users\\40595\\Downloads\\SchemeName.csv")
scheme_product_names <- read.csv("C:\\Users\\40595\\Downloads\\SchemeName_ProductName.csv")

#Removing unwanted columns
sal_df <- sal_df[,-c(3,4,5,10,11)]

#Sorting Year and Quarter columns
sal_df1 <- sal_df[with(sal_df, order(Year, Quarter)),]

#Shuffling Data
#sal_df1 <- sal_df[sample(nrow(sal_df)),]

#Replacing Product Names with Scheme Names

new_scheme_names <- scheme_names$Schema_Name
old_pdt_names <- unique(sal_df1$Product)

map <- setNames(new_scheme_names, old_pdt_names)
sal_df1$Product <- map[unlist(sal_df1$Product)]

#Inserting NAV for corresponding Scheme Names
nav <- scheme_names$NAV
map_nav <- setNames(nav, new_scheme_names)
sal_df1$NAV <- sal_df1$Product
sal_df1$NAV <- map_nav[unlist(sal_df1$NAV)]

#Inserting Product Names
sal_df1$Product_Name <- 0

for(i in 1:nrow(sal_df1))
    {
      a <- as.character(sal_df1[i,3])
      x <- which(scheme_product_names$Scheme.Name == a)
      sal_df1[i,8] <-  as.character(scheme_product_names[x,1])
    }
  

#Adding Random Fund Type
sal_df1$Fund_type <- sample(c('Money Market Funds', 'Balanced Funds', 'Equity Income Funds', 'Debt'), 88475, replace = TRUE)

#Adding Random Scheme Type
sal_df1$Scheme_type <- sample(c('Small Cap', 'Mid Cap', 'Large Cap'), 88475, replace =  TRUE)

#Adding Random Open/Close Ended
sal_df1$Open_Close <- sample(c('Open Ended', 'Close Ended'), 88475, replace = TRUE)

#Adding Bond Rating (Moody and S&P/Fitch Rating)
sal_df1$Moody_Rating <- sample(c('Aaa', 'Aa', 'A', 'Baa', 'Ba', 'B', 'Caa', 'Ca', 'C'), 88475, replace = TRUE)
sal_df1$Fitch_Rating <- sample(c('AAA', 'AA', 'A', 'BBB', 'BB', 'B', 'CCC', 'CC', 'C', 'D'), 88475, replace = TRUE)

#Reordering Columns
col_order <- c("Retailer_country", "Order_method.type", "Product_Name", "Year", "Quarter", "NAV", "Fund_type", "Scheme_type", "Open_Close", "Moody_Rating", "Fitch_Rating", "Product", "Revenue")
sal_df1 <- sal_df1[,col_order]

#Exporting transformed data to csv
Quarter_Sales_Data <- write.csv(sal_df1, file = "C:\\Users\\40595\\Downloads\\Quarter_Sales_Data.csv")


#Train Data
train_data <- sal_df1[1:67151,]
test_data <- sal_df1[67152:88475,]

#Label encoding for column "Product"
sal_df1$Product <- as.numeric(as.factor(sal_df1$Product))


#Implementing One-Hot encoding
sal_df1_dummy <- dummy.data.frame(sal_df1, names = c("Retailer_country", "Order_method.type", "Year", "Quarter", "NAV", "Product_Name", "Fund_type", "Scheme_type", "Open_Close", "Moody_Rating", "Product"), sep = '_')


#Trying Xgboost
y <- sal_df1[1:67151, 13]

xgb <- xgboost(data = data.matrix(sal_df1_dummy[1:67151,]), 
               label = y,
               booster = "gbtree", 
               objective = "reg:linear", 
               max.depth = 10, 
               eta = 0.5, 
               nthread = 5, 
               nround = 5, 
               min_child_weight = 1, 
               subsample = 1, 
               colsample_bytree = 1, 
               num_parallel_tree = 1
)

#Predicting Sales Value
y_pred <- predict(xgb, data.matrix(sal_df1_dummy[67152:88475,]))
actual_data <- sal_df1[67152:88475,13] #Test Data

#Test Data
#test_data <- sal_df1[67152:88475,]
test_data$Predicted_Value <- y_pred
Sales_Predicted_Data <- write.csv(test_data, file = "C:\\Users\\40595\\Downloads\\Sales_Predicted_Data.csv")


#Calculating error percentage
err_perc <- ((actual_data - y_pred)/actual_data)*100
err_perc <- err_perc[is.finite(err_perc)] #Removing Infinite values
err_perc <- mean(err_perc) # error_Percentage 3.15%

#Filtering Data

filter_data <- function(is_historic, col_val_PN, col_val_Year, col_val_Quarter, col_val_FundType, col_val_Product){

col_cond_PN <- "Product_Name" 
col_cond_Year <- "Year" 
col_cond_Quarter <- "Quarter"
col_cond_FundType <- "Fund_type"
col_cond_Product <- "Product"

filter_Condition <- ''


if(col_val_PN!='')
{
  filter_Condition = paste(col_cond_PN, "==" , paste("'",col_val_PN,"'",sep=""))
  
}

if(col_val_Year!='')
{
  filter_Condition = paste(filter_Condition, '&', paste(col_cond_Year, "==" , col_val_Year))
  
}

if(col_val_Quarter!='')
{
  filter_Condition = paste(filter_Condition, '&', paste(col_cond_Quarter, "==" , paste("'",col_val_Quarter,"'",sep="")))
  
}

if(col_val_FundType!='')
{
  filter_Condition = paste(filter_Condition, '&', paste(col_cond_FundType, "==" , paste("'",col_val_FundType,"'",sep="")))
  
}

if(col_val_Product!='')
{
  filter_Condition = paste(filter_Condition, '&', paste(col_cond_Product, "==" , paste("'",col_val_Product,"'",sep="")))
  
}

#Getting Revenue Value

if(is_historic == 1){
  
  filtered_value <- train_data %>% select(Product_Name, Year, Quarter, Fund_type, Product, Revenue)%>%
    filter(eval(parse(text=filter_Condition)))
  
  aggr_revenue <- sum(filtered_value$Revenue)
}
else
{
  filtered_value <- test_data %>% select(Product_Name, Year, Quarter, Fund_type, Product, Predicted_Value)%>%
    filter(eval(parse(text=filter_Condition)))
  
  aggr_revenue <- sum(filtered_value$Predicted_Value) 
}

return(aggr_revenue)

}


#-------------------xxxxx----------------#

model_linear <- lm(Revenue ~ Retailer_country + Order_method.type + Retailer_type + Product_line + Product_type + Quarter, data = sal_df1[1:61932,])
summary(model_linear)

prediction_sales <- predict(model_linear, newdata = sal_df1[61933:88475,])


rforest_model <- randomForest(Revenue ~ Retailer_country + Order_method.type + Retailer_type + Product_line + Product_type + Quarter, data = sal_df1[1:61932,], ntree = 500)

sale_rf_predict <- predict(rforest_model, sal_df1[61933:88475,])

#actual <- sal_df1[61933:88475,9]

err_diff <- data.frame(actual, sale_rf_predict)

sal_df1_dummy <- sal_df1_dummy[,-c(207,220,221)]

model_linear_dm <- lm(Revenue ~. , data = sal_df1_dummy[1:61932,])
prediction_sales_dm <- predict(model_linear_dm, newdata = sal_df1_dummy[61933:88475,])

sal_df1_dummy <- cut(sal_df1_dummy$Revenue, breaks = c(0,1000,5000))

pdt_quatr <- sal_df1_dummy[,63:218]
pdt_qautr_test <- sal_df1_dummy[61933:88475, 63:217]
model_pdt_quatr <- lm(Revenue ~. , data = pdt_quatr[1:61932,])
predicted_quatr <- predict(model_pdt_quatr, newdata = pdt_qautr_test)


RMSE <- function(actualValue, predictedValue){
  sqrt(mean((actualValue - predictedValue)^2))
}

RMSE(y_pred,actual_data)
