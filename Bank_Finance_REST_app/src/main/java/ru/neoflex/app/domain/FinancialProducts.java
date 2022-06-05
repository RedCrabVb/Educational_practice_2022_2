package ru.neoflex.app.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "t_financial_products")
@Getter
@Setter
@NoArgsConstructor
public class FinancialProducts {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long financialProductsId;
    private String title;
    private String description;
}
