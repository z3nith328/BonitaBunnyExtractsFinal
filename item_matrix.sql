CREATE TABLE item_matrix (
    item_id TEXT PRIMARY KEY CHECK (
        (category = 'Cord' AND item_id ~* '^C[A-Z]{1,2}$') OR
        (category = 'Bead' AND item_id ~* '^B[A-Z]\d{1,3}$') OR
        (category = 'Pendant' AND item_id ~* '^P[A-Z]\d{1,2}$')
    ),

    category TEXT CHECK (category IN ('Cord', 'Bead', 'Pendant')) NOT NULL,

    material TEXT CHECK (
        (category = 'Cord' AND material IN ('Silver', 'Gold', 'Elastic')) OR
        (category IN ('Bead', 'Pendant') AND material IN ('Metal', 'Resin', 'Ceramic', 'Plastic', 'Wood'))
    ) NOT NULL,

    cord_size TEXT CHECK (
        (category = 'Cord' AND cord_size IN ('SWB', 'MWB', 'LWB', 'SWC', 'MWC', 'LWC', 'SWN', 'MWN', 'LWN', 
                                             'SMB', 'MMB', 'LMB', 'SMC', 'MMC', 'LMC', 'SMN', 'MMN', 'LMN', 
                                             'EMB', 'EWB', 'EMC', 'EWC')) OR
        (category != 'Cord' AND cord_size IS NULL)
    ) DEFAULT NULL,

    design TEXT DEFAULT NULL,

    cord_wt DECIMAL(10,2) CHECK (
        (category = 'Cord' AND (
            (material = 'Silver' AND cord_wt IN (1.20, 1.30, 1.50, 1.80, 2.00, 2.40, 2.80, 3.00, 3.50, 
                                                 3.60, 3.80, 4.20, 4.80, 5.00, 5.50, 6.00, 6.30, 7.00)) OR
            (material = 'Gold' AND cord_wt IN (1.50, 1.70, 2.00, 2.40, 2.60, 3.00, 3.40, 3.60, 4.20, 
                                               4.50, 4.80, 5.20, 6.00, 6.50, 7.00, 7.50, 7.80, 8.50)) OR
            (material = 'Elastic' AND cord_wt IN (1.20, 1.80, 2.50, 3.20))
        )) OR
        (category != 'Cord' AND cord_wt IS NULL)
    ) DEFAULT NULL,

    pendant_wt DECIMAL(10,2) DEFAULT NULL,  -- Updated by external Python script
    bead_wt DECIMAL(10,2) DEFAULT NULL,     -- Updated by external Python script

    cord_len DECIMAL(10,2) CHECK (
        (category = 'Cord' AND cord_len IN (170, 185, 200, 190, 205, 230, 330, 360, 400, 380, 420, 460, 
                                            450, 500, 600, 500, 560, 760, 170, 200, 350, 400)) OR
        (category != 'Cord' AND cord_len IS NULL)
    ) DEFAULT NULL,

    bead_diam DECIMAL(10,2) CHECK (
        (category = 'Bead' AND bead_diam = 12) OR
        (category != 'Bead' AND bead_diam IS NULL)
    ) DEFAULT NULL,

    pendant_width DECIMAL(10,2) DEFAULT NULL,  -- Updated by external Python script

    status TEXT CHECK (status IN ('Active', 'Discontinued')) NOT NULL DEFAULT 'Active',

    first_listed_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    item_disc_flag BOOLEAN DEFAULT FALSE,

    item_disc_type TEXT CHECK (item_disc_type IN ('Percentage', 'Flat Amount')) DEFAULT NULL,

    item_disc_amt DECIMAL(10,2) DEFAULT NULL,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

