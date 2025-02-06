# BonitaBunnyExtractsFinal
                                                                ┌───────────────────────────┐                                
                                                                │Customers                  │                                
                                                                ├───────────────────────────┤                                
                                                                │+ customer_id : SERIAL (PK)│                                
                                                                │-- Personal Info --        │                                
                                                                │first_name : TEXT          │                                
                                                                │last_name : TEXT           │                                
                                                                │email : TEXT UNIQUE        │                                
                                                                │phone_number : TEXT UNIQUE │                                
                                                                │address : TEXT             │                                
                                                                │city : TEXT                │                                
                                                                │state : TEXT               │                                
                                                                │zip_code : TEXT            │                                
                                                                │country : TEXT             │                                
                                                                └───────────────────────────┘                                
                                                                               |                                             
                                                                               |                                             
                                                                ┌───────────────────────────┐                                
                                                                │Orders                     │                                
                                                                ├───────────────────────────┤                                
                                                                │+ order_id : SERIAL (PK)   │                                
                                                                │sub_order_id : INT         │                                
                                                                │customer_id : INT (FK)     │                                
                                                                │order_status : TEXT        │                                
                                                                │order_date : TIMESTAMP     │                                
                                                                │order_type : TEXT          │                                
                                                                │shipping_fee : DECIMAL     │                                
                                                                │total_order_price : DECIMAL│                                
                                                                │return_id : INT (FK)       │                                
                                                                └───────────────────────────┘                                
                                                                               |                                             
                               ┌─────────────────────────────┐   ┌─────────────────────────┐                                 
                               │Order Items                  │   │Returns                  │   ┌────────────────────────────┐
                               ├─────────────────────────────┤   ├─────────────────────────┤   │Order Status Tracking       │
                               │+ order_id : INT (PK, FK)    │   │+ return_id : SERIAL (PK)│   ├────────────────────────────┤
                               │+ sub_order_id : INT (PK, FK)│   │order_id : INT (FK)      │   │+ status_id : SERIAL (PK)   │
                               │+ item_id : TEXT (PK, FK)    │   │sub_order_id : INT (FK)  │   │order_id : INT (FK)         │
                               │item_type : TEXT             │   │return_reason : TEXT     │   │status : TEXT               │
                               │quantity : INT               │   │return_status : TEXT     │   │status_timestamp : TIMESTAMP│
                               │item_price : DECIMAL         │   │refund_amount : DECIMAL  │   └────────────────────────────┘
                               └─────────────────────────────┘   └─────────────────────────┘                                 
                                               |                                                                             
                              Central Node to Order Processing                                                             
                               ┌─────────────────────────────┐                                                               
                               │Item Matrix                  │                                                               
                               ├─────────────────────────────┤                                                               
                               │+ item_id : TEXT (PK)        │                                                               
                               │category : TEXT              │                                                               
                               │material : TEXT              │                                                               
                               │status : TEXT                │                                                               
                               │first_listed_date : TIMESTAMP│                                                               
                               └─────────────────────────────┘ 
                            Central Node to Inventory/Supplier Mgmt
                                               |                                                                             
                               ┌─────────────────────────────┐                                                               
                               │Inventory Levels             │                                                               
                               ├─────────────────────────────┤                                                               
                               │+ item_id : TEXT (PK, FK)    │                                                               
                               │supplier_id : INT (FK)       │                                                               
                               │supplier_name : TEXT         │                                                               
                               │current_level : INT          │                                                               
                               │cost_per_unit : DECIMAL      │                                                               
                               │current_price : DECIMAL      │                                                               
                               │last_reorder_date : TIMESTAMP│                                                               
                               └─────────────────────────────┘                                                               
               |                                |                                |                                           
┌───────────────────────────┐  ┌─────────────────────────────┐   ┌───────────────────────────────┐                           
│Suppliers                  │  │Historical Inventory Levels  │   │Inventory Demand Forecasting   │                           
├───────────────────────────┤  ├─────────────────────────────┤   ├───────────────────────────────┤                           
│+ supplier_id : SERIAL (PK)│  │+ history_id : SERIAL (PK)   │   │+ item_id : INT (PK, FK)       │                           
│supplier_name : TEXT       │  │item_id : INT (FK)           │   │historical_sales_volume : INT  │                           
│item_id : TEXT (FK)        │  │current_level : INT          │   │forecasted_demand : INT        │                           
│last_order_qty : INT       │  │cost_per_unit : DECIMAL      │   │moving_average_demand : DECIMAL│                           
│last_order_date : TIMESTAMP│  │last_reorder_date : TIMESTAMP│   │demand_trend_indicator : TEXT  │                           
└───────────────────────────┘  └─────────────────────────────┘   └───────────────────────────────┘                           
              |                                                                                                              
              |                                                                                                              
┌───────────────────────────┐                                                                                                
│Resupply Schedule          │                                                                                                
├───────────────────────────┤                                                                                                
│+ schedule_id : SERIAL (PK)│                                                                                                
│supplier_id : INT (FK)     │                                                                                                
│item_id : INT (FK)         │                                                                                                
│reorder_qty : INT          │                                                                                                
│supplier_lead_time : INT   │                                                                                                
└───────────────────────────┘                                                                                     
